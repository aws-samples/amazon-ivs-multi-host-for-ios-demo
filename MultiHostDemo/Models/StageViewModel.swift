//
//  StageViewModel.swift
//  Multihost
//
//  Created by Uldis Zingis on 09/06/2022.
//

import Foundation
import AmazonIVSBroadcast
import SwiftUI

class StageViewModel: NSObject, ObservableObject {
    let services: ServicesManager

    @Published var primaryCameraName = "None"
    @Published var primaryMicrophoneName = "None"
    @Published var allStages: [StageDetails] = []
    @Published private(set) var notifications: [Notification] = [] {
        didSet {
            // Hide success notifications after 5 seconds
            if let newNotification = notifications.last, newNotification.type == .success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                    if let index = self.notifications.firstIndex(of: newNotification) {
                        self.notifications.remove(at: index)
                    }
                })
            }
        }
    }

    @Published var sessionRunning: Bool = false
    @Published var isBroadcasting: Bool = false
    @Published var stageConnectionState: IVSStageConnectionState = .disconnected
    @Published var localUserAudioMuted: Bool = false
    @Published var localUserVideoMuted: Bool = false
    @Published var localUserWantsPublish: Bool = true

    @Published var participantsData: [ParticipantData] = [] {
        didSet {
            updateBroadcastSlots()
        }
    }

    var participantCount: Int {
        return participantsData.count
    }

    private(set) var videoConfig = IVSLocalStageStreamVideoConfiguration()
    private let broadcastConfig = IVSPresets.configurations().standardPortrait()

    var selectedCamera: IVSDeviceDescriptor? {
        didSet {
            primaryCameraName = selectedCamera?.friendlyName ?? "None"
        }
    }

    var selectedMicrophone: IVSDeviceDescriptor? {
        didSet {
            primaryMicrophoneName = selectedMicrophone?.friendlyName ?? "None"
        }
    }

    private var shouldRepublishWhenEnteringForeground = false
    private var stage: IVSStage?
    var localStreams: [IVSLocalStageStream] = [] {
        didSet { updateBroadcastBindings() }
    }
    var broadcastSession: IVSBroadcastSession?
    private var broadcastSlots: [IVSMixerSlotConfiguration] = [] {
        didSet {
            guard let broadcastSession = broadcastSession else { return }
            let oldSlots = broadcastSession.mixer.slots()
            // We're going to remove old slots, then add new slots, and update existing slots.

            // Removing old slots
            oldSlots.forEach { oldSlot in
                if !broadcastSlots.contains(where: { $0.name == oldSlot.name }) {
                    broadcastSession.mixer.removeSlot(withName: oldSlot.name)
                }
            }

            // Adding new slots
            broadcastSlots.forEach { newSlot in
                if !oldSlots.contains(where: { $0.name == newSlot.name }) {
                    broadcastSession.mixer.addSlot(newSlot)
                }
            }

            // Update existing slots
            broadcastSlots.forEach { newSlot in
                if oldSlots.contains(where: { $0.name == newSlot.name }) {
                    broadcastSession.mixer.transitionSlot(withName: newSlot.name, toState: newSlot, duration: 0.3)
                }
            }
        }
    }

    let deviceDiscovery = IVSDeviceDiscovery()
    let deviceSlotName = UUID().uuidString
    var broadcastDelegate: BroadcastDelegate?
    var currentJoinToken: String = ""

    init(services: ServicesManager) {
        self.services = services
        super.init()
        self.setupLocalUser()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(mediaServicesLost),
                                               name: AVAudioSession.mediaServicesWereLostNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(mediaServicesReset),
                                               name: AVAudioSession.mediaServicesWereResetNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.mediaServicesWereLostNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
    }

    private func setupLocalUser() {
        setLocalCamera(to: .front)

#if targetEnvironment(simulator)
        let devices: [Any] = []
#else
        let devices = deviceDiscovery.listLocalDevices()
#endif

        if let microphone = devices
            .compactMap({ $0 as? IVSMicrophone })
            .first
        {
            microphone.delegate = self
            microphone.isEchoCancellationEnabled = true
            self.localStreams.append(IVSLocalStageStream(device: microphone))
        }

        let localParticipant = ParticipantData(isLocal: true, info: nil, participantId: nil)
        localParticipant.username = services.user.username ?? ""
        localParticipant.avatarUrl = services.user.avatarUrl ?? ""
        self.participantsData.append(localParticipant)
        self.participantsData[0].streams = self.localStreams
    }

    @objc private func applicationDidEnterBackground() {
        let connectingOrConnected = (stageConnectionState == .connecting) || (stageConnectionState == .connected)

        if connectingOrConnected {
            shouldRepublishWhenEnteringForeground = localUserWantsPublish
            localUserWantsPublish = false
            participantsData
                .compactMap { $0.participantId }
                .forEach {
                    mutatingParticipant($0) { data in
                        data.requiresAudioOnly = true
                    }
                }
            stage?.refreshStrategy()
        }
    }

    @objc private func applicationWillEnterForeground() {
        if shouldRepublishWhenEnteringForeground {
            localUserWantsPublish = true
            shouldRepublishWhenEnteringForeground = false
        }
        if !participantsData.isEmpty {
            participantsData
                .compactMap { $0.participantId }
                .forEach {
                    mutatingParticipant($0) { data in
                        data.requiresAudioOnly = false
                    }
                }
            stage?.refreshStrategy()
        }
    }

    @objc private func mediaServicesLost() {
        // once media services are lost, errors will start to fire. Kill the session ASAP and wait for the reset
        // notification to stream again.
        destroyBroadcastSession()
        print("ℹ ❌ media services were lost")
        appendErrorNotification("The Media Services on this device have been lost, no video or audio work can be done for a couple seconds. Please wait…")
    }

    @objc private func mediaServicesReset() {
        print("ℹ media services were reset")
        appendSuccessNotification("Media services restored - OK to start broadcast again")
    }

    func initializeStage(onComplete: @escaping () -> Void) {
        IVSSession.applicationAudioSessionStrategy = .playAndRecordDefaultToSpeaker
        IVSBroadcastSession.applicationAudioSessionStrategy = .playAndRecordDefaultToSpeaker
        DispatchQueue.main.async {
            self.broadcastDelegate = BroadcastDelegate()
            self.broadcastDelegate?.viewModel = self
        }

        onComplete()
    }

    func clearNotifications() {
        DispatchQueue.main.async {
            self.notifications = []
        }
    }

    func createStage(user: User, onComplete: @escaping (Bool) -> Void) {
        services.server.createStage(user: user) { [weak self] success, error in
            if success {
                print("ℹ New stage created for user \(user.userId)")
                onComplete(true)
            } else {
                print("ℹ ❌ Could not create stage: \(error ?? "")")
                self?.appendErrorNotification(error ?? "")
                onComplete(false)
            }
        }
    }

    func deleteStage(onComplete: @escaping () -> Void) {
        services.server.deleteStage() {
            print("ℹ Stage deleted")
            onComplete()
        }
    }

    func getToken(for stage: StageDetails, onComplete: @escaping (StageJoinDetails?, String?) -> Void) {
        services.server.joinStage(user: services.user, groupId: stage.groupId) { [weak self] stageJoinResponse, error in
            let token = stageJoinResponse?.stage
            if token == nil {
                self?.appendErrorNotification("Can't join stage - missing stage token")
            }
            self?.services.user.participantId = stageJoinResponse?.stage.token.participantId
            onComplete(stageJoinResponse, nil)
        }
    }

    func joinAsParticipant(_ token: String, onSuccess: () -> Void) {
        joinStage(token, onSuccess: onSuccess)

        if let chat = services.server.stageJoinDetails?.chat {
            services.connect(to: chat)
        }
    }

    func joinAsHost(onComplete: @escaping (Bool) -> Void) {
        print("ℹ Joining stage as host...")
        guard let hostToken = services.server.stageHostDetails?.stage.token else {
            print("❌ Can't join - no auth token in host stage details")
            self.appendErrorNotification("Can't join created stage - missing host stage details")
            onComplete(false)
            return
        }

        if let chat = services.server.stageHostDetails?.chat {
            services.connect(to: chat)
        }

        joinStage(hostToken.token) {
            print("ℹ Stage joined as host")
            onComplete(true)
        }
    }

    private func joinStage(_ token: String, onSuccess: () -> Void) {
        do {
            self.stage = nil
            let stage = try IVSStage(token: token, strategy: self)
            stage.addRenderer(self)
            stage.errorDelegate = self
            try stage.join()
            self.stage = stage
            appendSuccessNotification(self.services.user.isHost ? "Stage Created" : "Stage Joined")
            print("ℹ stage joined")
            currentJoinToken = token
            DispatchQueue.main.async {
                self.sessionRunning = true
            }
            onSuccess()

        } catch {
            print("ℹ ❌ Error joining stage: \(error)")
        }
    }

    func leaveStage() {
        print("ℹ Leaving stage")
        stage?.leave()
        while participantsData.count > 1 {
            participantsData.remove(at: participantsData.count - 1)
        }
    }

    func getAllStages(initial: Bool = false, _ onComplete: @escaping ([StageDetails]) -> Void) {
        if initial {
            allStages = []
        }
        services.server.getAllStages { [weak self] success, stages, error in
            DispatchQueue.main.async {
                if success {
                    self?.allStages = stages ?? []
                    print("ℹ got \(self?.allStages.count ?? 0) stages")
                }

                if self?.allStages.count == 0 {
                    // Add empty stage to suppport List view refreshable when there are no stages
                    self?.allStages = [StageDetails.empty]
                }
                onComplete(self?.allStages ?? [])
            }
        }
    }


    func endSession() {
        print("ℹ Ending session...")
        sessionRunning = false
        leaveStage()
        destroyBroadcastSession()
        stage = nil
    }

    func toggleLocalAudioMute() {
        localStreams
            .filter { $0.device is IVSAudioDevice }
            .forEach {
                $0.setMuted(!$0.isMuted)
                localUserAudioMuted = $0.isMuted
                if let audioDevice = $0.device as? IVSAudioDevice {
                    audioDevice.setGain(localUserAudioMuted ? 0 : 1)
                }
            }
        services.user.audioOn = !localUserAudioMuted
        print("ℹ Toggled audio, is muted: \(localUserAudioMuted)")
    }

    func toggleLocalVideoMute() {
        localStreams
            .filter { $0.device is IVSImageDevice }
            .forEach {
                $0.setMuted(!$0.isMuted)
                localUserVideoMuted = $0.isMuted
                if isBroadcasting {
                    if $0.isMuted {
                        broadcastSession?.detach($0.device.descriptor())
                    } else {
                        broadcastSession?.attach($0.device, toSlotWithName: participantsData[0].broadcastSlotName)
                    }
                }
            }
        services.user.videoOn = !localUserVideoMuted
        print("ℹ Toggled video, is muted: \(localUserVideoMuted)")
    }

    func toggleRemoteAudioMute(for participantId: String?) {
        mutatingParticipant(participantId) { data in
            data.toggleAudioMute()
        }
    }

    func toggleRemoteVideoMute(for participantId: String?) {
        mutatingParticipant(participantId) { data in
            data.toggleVideoMute()
        }
    }

    func toggleBroadcasting() {
        guard setupBroadcastSessionIfNeeded() else { return }
        if isBroadcasting {
            print("ℹ Stopping broadcast")
            broadcastSession?.stop()
            isBroadcasting = false
        } else {
            do {
                guard let stageChannel = services.server.stageHostDetails?.channel else {
                    print("ℹ ❌ Can't start broadcasting - hostStageDetails not set")
                    appendWarningNotification("Can't start - missing host stage details")
                    return
                }
                print("ℹ Starting broadcast")
                try broadcastSession?.start(with: URL(string: "rtmps://\(stageChannel.ingestEndpoint)")!,
                                            streamKey: stageChannel.streamKey)
                isBroadcasting = true
            } catch {
                print("ℹ ❌ error starting broadcast: \(error)")
                appendErrorNotification(error.localizedDescription)
                isBroadcasting = false
                broadcastSession = nil
            }
        }
    }

    func swapCamera() {
        print("ℹ swapping camera to \(selectedCamera?.position == .front ? "back" : "front")")
        setLocalCamera(to: selectedCamera?.position == .front ? .back : .front)
    }

    func appendSuccessNotification(_ message: String) {
        DispatchQueue.main.async {
            self.notifications.removeAll(where: { $0.type == .success })
            self.notifications.append(Notification(type: .success, message: message))
        }
    }

    func appendWarningNotification(_ message: String) {
        DispatchQueue.main.async {
            self.notifications.removeAll(where: { $0.type == .warning })
            self.notifications.append(Notification(type: .warning, message: message))
        }
    }

    func appendErrorNotification(_ message: String) {
        DispatchQueue.main.async {
            self.notifications.removeAll(where: { $0.type == .error })
            self.notifications.append(Notification(type: .error, message: message))
        }
    }

    func removeNotification(_ notification: Notification) {
        if let index = notifications.firstIndex(of: notification) {
            DispatchQueue.main.async {
                self.notifications.remove(at: index)
            }
        }
    }

    private func setLocalCamera(to position: IVSDevicePosition) {
#if targetEnvironment(simulator)
        let devices: [Any] = []
#else
        let devices = deviceDiscovery.listLocalDevices()
#endif

        if let camera = devices.compactMap({ $0 as? IVSCamera }).first {
            if let cameraSource = camera.listAvailableInputSources().first(where: { $0.position == position }) {
                print("ℹ local camera source: \(cameraSource)")
                camera.setPreferredInputSource(cameraSource) { [weak self] in
                    if let error = $0 {
                        print("ℹ ❌ Error on setting preferred input source: \(error)")
                        self?.appendErrorNotification(error.localizedDescription)
                    } else {
                        self?.selectedCamera = cameraSource
                    }
                    print("ℹ localy selected camera: \(String(describing: self?.selectedCamera))")
                }
            }
            self.localStreams.append(IVSLocalStageStream(device: camera, configuration: self.videoConfig))
        }
    }

    func updateLocalVideoStreamConfiguration(_ config: IVSLocalStageStreamVideoConfiguration) {
        videoConfig = config
        localStreams
            .filter { $0.device is IVSImageDevice }
            .forEach {
                print("Updating VideoConfig for \($0.device.descriptor().friendlyName)")
                $0.setConfiguration(videoConfig)
            }
    }

    private func updateBroadcastSlots() {
        do {
            let participantsToBroadcast = participantsData.filter { $0.wantsBroadcast }
            broadcastSlots = try StageLayoutCalculator().calculateFrames(participantCount: participantsToBroadcast.count,
                                                                         width: broadcastConfig.video.size.width,
                                                                         height: broadcastConfig.video.size.height,
                                                                         padding: 10)
            .enumerated()
            .map { (index, frame) in
                let slot = IVSMixerSlotConfiguration()
                try slot.setName(participantsToBroadcast[index].broadcastSlotName)
                slot.position = frame.origin
                slot.size = frame.size
                slot.aspect = .fill
                slot.zIndex = Int32(index)
                return slot
            }
            updateBroadcastBindings()
        } catch {
            print("ℹ ❌ error updating broadcast slots: \(error)")
            appendErrorNotification(error.localizedDescription)
        }
    }

    private func updateBroadcastBindings() {
        guard let broadcastSession = broadcastSession else { return }

        broadcastSession.awaitDeviceChanges { [weak self] in
            var attachedDevices = broadcastSession.listAttachedDevices()
            self?.participantsData
                .filter { $0.wantsBroadcast }
                .forEach { participant in
                    participant.streams.forEach { stream in
                        let slotName = participant.broadcastSlotName

                        if stream.isMuted {
                            broadcastSession.detach(stream.device)
                        } else {
                            if attachedDevices.contains(where: { $0 === stream.device }) {
                                if broadcastSession.mixer.binding(for: stream.device) != slotName {
                                    broadcastSession.mixer.bindDevice(stream.device, toSlotWithName: slotName)
                                }
                            } else {
                                broadcastSession.attach(stream.device, toSlotWithName: slotName)
                            }
                        }

                        attachedDevices.removeAll(where: { $0 === stream.device })
                    }
                }
            // Anything still in the attached devices list at the end shouldn't be attached anymore
            attachedDevices.forEach {
                broadcastSession.detach($0)
            }
        }
    }

    private func destroyBroadcastSession() {
        if isBroadcasting {
            print("ℹ Destroying broadcast session")
            broadcastSession?.stop()
            broadcastSession = nil
            isBroadcasting = false
        }
    }

    @discardableResult
    private func setupBroadcastSessionIfNeeded() -> Bool {
        guard broadcastSession == nil else {
            print("ℹ Session not created, it already existed")
            return true
        }
        do {
            broadcastSession = try IVSBroadcastSession(configuration: broadcastConfig,
                                                       descriptors: nil,
                                                       delegate: broadcastDelegate)
            updateBroadcastSlots()
            return true
        } catch {
            print("ℹ ❌ error setting up BroadcastSession: \(error)")
            appendErrorNotification(error.localizedDescription)
            return false
        }
    }

    // MARK: - SessionConfigurable

    func listAvailableDevices() -> [IVSDeviceDescriptor] {
#if targetEnvironment(simulator)
        let devices: [Any] = []
#else
        let devices = deviceDiscovery.listLocalDevices()
#endif

        return devices.flatMap { device -> [IVSDeviceDescriptor] in
            if let camera = device as? IVSCamera {
                return camera.listAvailableInputSources()
            } else if let microphone = device as? IVSMicrophone {
                return microphone.listAvailableInputSources()
            }
            return []
        }
    }

    func setCamera(_ device: IVSDeviceDescriptor?) {
        setDevice(device, outDevice: \Self.selectedCamera, type: IVSCamera.self, logSource: "setCamera")
    }

    func setMicrophone(_ device: IVSDeviceDescriptor?) {
        setDevice(device, outDevice: \Self.selectedMicrophone, type: IVSMicrophone.self, logSource: "setMicrophone")
    }

    private func setDevice<DeviceType: IVSMultiSourceDevice>(_ inDevice: IVSDeviceDescriptor?,
                                                             outDevice: ReferenceWritableKeyPath<StageViewModel, IVSDeviceDescriptor?>,
                                                             type: DeviceType.Type,
                                                             logSource: String) {

#if targetEnvironment(simulator)
        let devices: [Any] = []
#else
        let devices = deviceDiscovery.listLocalDevices()
#endif

        guard let localDevice = devices.compactMap({ $0 as? DeviceType }).first else { return }

        if let inputSource = inDevice {
            localDevice.setPreferredInputSource(inputSource) { [weak self] in
                if let error = $0 {
                    print("ℹ ❌ error setting device: \(error)")
                    self?.appendErrorNotification(error.localizedDescription)
                } else {
                    self?[keyPath: outDevice] = inputSource
                }
            }
        }

        var localStreamsDidChange = false
        let index = localStreams.firstIndex(where: { $0.device === localDevice })
        if let index = index, inDevice == nil {
            localStreams.remove(at: index)
            localStreamsDidChange = true
        } else if index == nil, inDevice != nil {
            localStreams.append(IVSLocalStageStream(device: localDevice, configuration: videoConfig))
            localStreamsDidChange = true
        }

        if localStreamsDidChange {
            self[keyPath: outDevice] = inDevice
            stage?.refreshStrategy()
            participantsData[0].streams = localStreams
        }
    }

    func kick(_ participantId: String) {
        guard let stage = services.server.stageHostDetails?.stage else {
            print("ℹ ❌ Can't disconnect users without host stage details")
            return
        }
        services.server.disconnect(participantId, from: stage.id, userId: services.user.userId)
    }

    func toggleSubscribed(forParticipant participantId: String) {
        mutatingParticipant(participantId) { $0.wantsSubscribed.toggle() }
        stage?.refreshStrategy()
    }

    func toggleAudioOnlySubscribe(forParticipant participantId: String) {
        var shouldRefresh = false
        mutatingParticipant(participantId) {
            shouldRefresh = $0.wantsSubscribed
            $0.wantsAudioOnly.toggle()
        }
        if shouldRefresh {
            stage?.refreshStrategy()
        }
    }

    func toggleBroadcasting(forParticipant participantId: String?) {
        mutatingParticipant(participantId) { $0.wantsBroadcast.toggle() }
    }

    func dataForParticipant(_ participantId: String) -> ParticipantData? {
        guard let participant = participantsData.first(where: { $0.participantId == participantId }) else {
            print("ℹ ❌ Could not find data for participant with id \(participantId)")
            return nil
        }
        return participant
    }

    func mutatingParticipant(_ participantId: String?, modifier: (inout ParticipantData) -> Void) {
        guard let index = participantsData.firstIndex(where: { $0.participantId == participantId }) else {
            fatalError("Something is out of sync, investigate")
        }

        var participant = participantsData[index]
        modifier(&participant)
        participantsData[index] = participant
    }
}
