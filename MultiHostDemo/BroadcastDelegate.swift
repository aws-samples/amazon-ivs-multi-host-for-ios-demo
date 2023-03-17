//
//  BroadcastDelegateViewController.swift
//  Multihost
//
//  Created by Uldis Zingis on 09/06/2022.
//

import AmazonIVSBroadcast

class BroadcastDelegate: UIViewController, IVSBroadcastSession.Delegate {
    var viewModel: StageViewModel?

    func broadcastSession(_ session: IVSBroadcastSession, didChange state: IVSBroadcastSession.State) {
        print("ℹ IVSBroadcastSession state did change to \(state.text)")
        DispatchQueue.main.async { [weak self] in
            switch state {
                case .invalid, .disconnected, .error:
                    self?.viewModel?.isBroadcasting = false
                    self?.viewModel?.broadcastSession = nil
                case .connecting, .connected:
                    self?.viewModel?.isBroadcasting = true
                @unknown default:
                    print("ℹ ❌ IVSBroadcastSession did emit unknown state")
                    fatalError()
            }
        }
    }

    func broadcastSession(_ session: IVSBroadcastSession, didEmitError error: Error) {
        print("ℹ ❌ IVSBroadcastSession did emit error \(error)")
        DispatchQueue.main.async { [weak self] in
            self?.viewModel?.notifications.append(Notification(type: .error, message: error.localizedDescription))
        }
    }
}

extension IVSBroadcastSession.State {
    var text: String {
        switch self {
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting"
            case .connected: return "Connected"
            case .invalid:  return "Invalid"
            case .error:  return "Error"
            @unknown default: return "Unknown broadcast session state"
        }
    }
}

