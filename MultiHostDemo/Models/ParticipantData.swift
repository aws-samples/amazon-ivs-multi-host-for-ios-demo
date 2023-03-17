//
//  ParticipantData.swift
//  Stages-demo
//
//  Created by Uldis Zingis on 26/01/2023.
//

import Foundation
import AmazonIVSBroadcast

class ParticipantData: Identifiable, ObservableObject {
    let id: String
    let isLocal: Bool
    var participantId: String?
    var username: String = ""
    var avatarUrl: String = ""
    var isHost: Bool = false

    @Published var info: IVSParticipantInfo?
    @Published var publishState: IVSParticipantPublishState = .notPublished
    @Published var streams: [IVSStageStream] = [] {
        didSet {
            videoMuted = streams.first(where: { $0.device is IVSImageDevice })?.isMuted ?? false
            audioMuted = streams.first(where: { $0.device is IVSAudioDevice })?.isMuted ?? false
        }
    }

    // The host-app has explicitly requested audio only
    @Published var wantsAudioOnly = false
    // The host-app is in the background and requires audio only
    @Published var requiresAudioOnly = false
    // The actual audio only state to be used for subscriptions
    var isAudioOnly: Bool {
        return wantsAudioOnly || requiresAudioOnly
    }

    @Published var wantsSubscribed = true
    @Published var wantsBroadcast = true
    @Published var videoMuted = false
    @Published var audioMuted = false

    var broadcastSlotName: String {
        if isLocal {
            return "localUser"
        } else {
            guard let participantId = participantId else {
                fatalError("non-local participants must have a participantId")
            }
            return "participant-\(participantId)"
        }
    }

    private var imageDevice: IVSImageDevice? {
        return streams.lazy.compactMap { $0.device as? IVSImageDevice }.first
    }

    var previewView: ParticipantView {
        var preview: IVSImagePreviewView?
        do {
            preview = try imageDevice?.previewView(with: .fill)
        } catch {
            print("ℹ ❌ got error when trying to get participant preview view from IVSImageDevice: \(error)")
        }
        let view = ParticipantView(preview: preview, participant: self)
        return view
    }

    init(isLocal: Bool, info: IVSParticipantInfo?, participantId: String?) {
        self.id = UUID().uuidString
        self.isLocal = isLocal
        self.participantId = participantId
        self.info = info
        if !isLocal {
            self.username = info?.attributes["username"] as? String ?? ""
            self.avatarUrl = info?.attributes["avatarUrl"] as? String ?? ""
            self.isHost = Bool(info?.attributes["isHost"] as? String ?? "false") ?? false
        }
    }

    func toggleAudioMute() {
        audioMuted = !audioMuted
        streams
            .compactMap({ $0.device as? IVSAudioDevice })
            .first?
            .setGain(audioMuted ? 0 : 1)
    }

    func toggleVideoMute() {
        videoMuted = !videoMuted
        wantsBroadcast = !videoMuted
    }

    func mutatingStreams(_ stream: IVSStageStream?, modifier: (inout IVSStageStream) -> Void) {
        guard let index = streams.firstIndex(where: { $0.device.descriptor().urn == stream?.device.descriptor().urn }) else {
            fatalError("Something is out of sync, investigate")
        }

        var stream = streams[index]
        modifier(&stream)
        streams[index] = stream
    }
}
