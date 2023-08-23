//
//  StageViewModel+Extensions.swift
//  Stages-demo
//
//  Created by Uldis Zingis on 26/01/2023.
//

import AmazonIVSBroadcast

extension StageViewModel: ServerDelegate {
    func didEmitError(error: String) {
        print("ℹ ❌ \(error)")
        appendErrorNotification(error)
    }
}

extension StageViewModel: IVSMicrophoneDelegate {
    func underlyingInputSourceChanged(for microphone: IVSMicrophone, toInputSource inputSource: IVSDeviceDescriptor?) {
        guard localStreams.contains(where: { $0.device === microphone }) else { return }
        selectedMicrophone = inputSource
    }
}

extension StageViewModel: IVSErrorDelegate {
    func source(_ source: IVSErrorSource, didEmitError error: Error) {
        print("ℹ ❌ IVSError \(error)")
        appendErrorNotification(error.localizedDescription)
    }
}

extension StageViewModel: IVSStageStrategy {
    func stage(_ stage: IVSStage, shouldSubscribeToParticipant participant: IVSParticipantInfo) -> IVSStageSubscribeType {
        guard let data = dataForParticipant(participant.participantId) else {
            return .none
        }
        let subType: IVSStageSubscribeType
        if data.wantsSubscribed {
            subType = data.isAudioOnly ? .audioOnly : .audioVideo
        } else {
            subType = .none
        }

        return subType
    }

    func stage(_ stage: IVSStage, shouldPublishParticipant participant: IVSParticipantInfo) -> Bool {
        return localUserWantsPublish
    }

    func stage(_ stage: IVSStage, streamsToPublishForParticipant participant: IVSParticipantInfo) -> [IVSLocalStageStream] {
        guard participantsData[0].participantId == participant.participantId else {
            return []
        }
        return localStreams
    }
}

extension StageViewModel: IVSStageRenderer {
    func stage(_ stage: IVSStage, participantDidJoin participant: IVSParticipantInfo) {
        print("ℹ participant \(participant.participantId) did join")
        if participant.isLocal {
            participantsData[0].participantId = participant.participantId
        } else {
            participantsData.append(ParticipantData(isLocal: false, info: participant, participantId: participant.participantId))
        }
    }

    func stage(_ stage: IVSStage, participantDidLeave participant: IVSParticipantInfo) {
        print("ℹ participant \(participant.participantId) did leave")
        if participant.isLocal {
            participantsData[0].participantId = nil
        } else {
            if let index = participantsData.firstIndex(where: { $0.participantId == participant.participantId }) {
                participantsData.remove(at: index)
            }
        }
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didChange publishState: IVSParticipantPublishState) {
        print("ℹ participant \(participant.participantId) didChangePublishState to '\(publishState.text)'")
        mutatingParticipant(participant.participantId) { data in
            data.publishState = publishState
        }
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didChange subscribeState: IVSParticipantSubscribeState) {
        print("ℹ participant \(participant.participantId) didChangeSubscribeState to '\(subscribeState.text)'")
        
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didAdd streams: [IVSStageStream]) {
        print("ℹ participant \(participant.participantId) didAdd \(streams.count) streams")
        if participant.isLocal { return }

        mutatingParticipant(participant.participantId) { data in
            data.streams.append(contentsOf: streams)
        }
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didRemove streams: [IVSStageStream]) {
        print("ℹ participant \(participant.participantId) didRemove \(streams.count) streams")
        if participant.isLocal { return }

        mutatingParticipant(participant.participantId) { data in
            let oldUrns = streams.map { $0.device.descriptor().urn }
            data.streams.removeAll(where: { stream in
                return oldUrns.contains(stream.device.descriptor().urn)
            })
        }
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didChangeMutedStreams streams: [IVSStageStream]) {
        print("ℹ participant \(participant.participantId) didChangeMutedStreams")
        if participant.isLocal { return }

        for stream in streams {
            print("ℹ is muted: \(stream.isMuted)")
            mutatingParticipant(participant.participantId) { data in
                if let index = data.streams.firstIndex(of: stream) {
                    data.streams[index] = stream
                }
            }
        }
    }

    func stage(_ stage: IVSStage, didChange connectionState: IVSStageConnectionState, withError error: Error?) {
        print("ℹ didChangeConnectionStateWithError state '\(connectionState.text)', error: \(String(describing: error))")
        stageConnectionState = connectionState;
    }
}

extension IVSStageConnectionState {
    var text: String {
        switch self {
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting"
            case .connected: return "Connected"
            @unknown default: return "Unknown connection state"
        }
    }
}

extension IVSParticipantPublishState {
    var text: String {
        switch self {
            case .notPublished: return "Not Published"
            case .attemptingPublish: return "Attempting to Publish"
            case .published: return "Published"
            @unknown default: return "Unknown publish state"
        }
    }
}

extension IVSParticipantSubscribeState {
    var text: String {
        switch self {
            case .subscribed: return "Subscribed"
            case .notSubscribed: return "Not Subscribed"
            case .attemptingSubscribe: return "Attempting Subscribe"
            @unknown default: return "Unknown subscribe state"
        }
    }
}
