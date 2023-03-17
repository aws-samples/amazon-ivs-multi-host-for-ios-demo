//
//  WebsocketModel.swift
//  Multihost
//
//  Created by Uldis Zingis on 01/08/2022.
//

import Foundation
import SwiftUI

protocol ServerDelegate {
    func didEmitError(error: String)
}

class Server: ObservableObject {
    var delegate: ServerDelegate?
    var decoder = JSONDecoder()

    @Published var stageDetails: StageDetails?
    @Published var stageJoinDetails: StageJoinDetails?
    @Published var stageHostDetails: StageHostDetails?

    var joinedGroupId: String = ""
    var joinedStagePlaybackUrl: String = ""

    func getAllStages(_ onComplete: @escaping (Bool, [StageDetails]?, String?) -> Void) {
        send("POST", endpoint: "list", body: nil, onComplete: { success, data, errorMessage in

            guard let data = data else {
                onComplete(false, nil, "No data in response")
                return
            }

            do {
                let stages = try self.decoder.decode([StageDetails].self, from: data)
                onComplete(success, stages, errorMessage)
            } catch {
                print("❌ \(error)")
                self.delegate?.didEmitError(error: "Could not decode get all stages response: \(error.localizedDescription)")
                onComplete(false, nil, "No data in response")
                return
            }
        })
    }

    func createStage(user: User, onComplete: @escaping (Bool, String?) -> Void) {
        print("ℹ Creating new stage for user \(user.userId)")

        let body = """
            {
                "userId": "\(user.userId)",
                "attributes": {
                    "username": "\(user.username ?? "")",
                    "avatarUrl": "\(user.avatarUrl ?? "")"
                },
                "id": ""
            }
        """

        send("POST", endpoint: "create", body: body, onComplete: { [weak self] success, data, errorMessage in
            if let error = errorMessage {
                onComplete(false, error)
            }

            guard let data = data else {
                onComplete(false, "No data in response")
                return
            }

            do {
                self?.stageHostDetails = try self?.decoder.decode(StageHostDetails.self, from: data)
                print("ℹ got host stage details: \(String(describing: self?.stageHostDetails))")
            } catch {
                print("❌ \(error)")
                self?.delegate?.didEmitError(error: "Could not decode stage create response: \(error)")
                onComplete(false, "Could not decode stage create response")
                return
            }

            onComplete(success, errorMessage)
        })
    }

    func joinStage(user: User, groupId: String, onComplete: @escaping (StageJoinDetails?, String?) -> Void) {
        let body = """
            {
                "groupId": "\(groupId)",
                "userId": "\(user.userId)",
                "attributes": {
                    "avatarUrl": "\(user.avatarUrl ?? "")",
                    "username": "\(user.username ?? "")"
                }
            }
        """
        send("POST", endpoint: "join", body: body, onComplete: { [weak self] success, data, errorMessage in
            if let error = errorMessage {
                print("❌ Error on stage join: \(error)")
            }

            guard let data = data else {
                print("❌ No data in join stage response")
                onComplete(nil, "No data in response. \(errorMessage ?? "")")
                return
            }

            do {
                self?.stageJoinDetails = try self?.decoder.decode(StageJoinDetails.self, from: data)
                print("ℹ got stage join response: \(String(describing: self?.stageJoinDetails))")
                self?.joinedGroupId = groupId
                onComplete(self?.stageJoinDetails, nil)
            } catch {
                print("❌ \(error)")
                self?.delegate?.didEmitError(error: "Could not decode stage join response: \(error.localizedDescription)")
                onComplete(nil, error.localizedDescription)
                return
            }
        })
    }

    func deleteStage(onComplete: @escaping () -> Void) {
        guard let stage = stageHostDetails else {
            print("❌ Can't delete stage - not a host")
            return
        }

        print("ℹ Deleting created stage...")

        let body = """
            {
                "groupId": "\(stage.groupId)"
            }
        """

        send("DELETE", endpoint: "delete", body: body, onComplete: { _, _, errorMessage in
            if let error = errorMessage {
                print("❌ Error from delete stage response: \(error)")
            }
            onComplete()
        })
    }

    func disconnect(_ participantId: String, from groupId: String, userId: String) {
        let body = """
            {
                "groupId": "\(groupId)",
                "participantId": "\(participantId)",
                "reason": "Kicked by another user",
                "userId": "\(userId)"
            }
            """
        send("POST", endpoint: "disconnect", body: body) { [weak self] success, data, error in
            if let error = error {
                print("❌ Error disconnecting participant \(participantId): \(error)")
            }

            self?.joinedGroupId = ""
        }
    }

    private func send(_ method: String, endpoint: String, body: String?, onComplete: @escaping (Bool, Data?, String?) -> Void) {
        guard let url = URL(string: "\(Constants.API_URL)/\(endpoint)") else {
            delegate?.didEmitError(error: "Server url not set in Constats.swift")
            return
        }

        let session = URLSession(configuration: .default)
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.httpMethod = method
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = body.data(using: .utf8)
        }

        print("ℹ 🔗 sending \(method) '\(endpoint)' \(body != nil ? "with body: \(body!)" : "")")

        session.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                if ![200, 204].contains(httpResponse.statusCode) {
                    print("ℹ 🔗 Got status code \(httpResponse.statusCode) when sending \(request)")
                    self.delegate?.didEmitError(error: "Got status code \(httpResponse.statusCode) when sending \(request)")
                    if let data = data, let response = String(data: data, encoding: .utf8) {
                        print(response)
                        onComplete(false, nil, "\(httpResponse.statusCode) \(response)")
                    }
                    return
                }

                if let error = error {
                    print("ℹ 🔗 ❌ Failed to send '\(method)' to '\(endpoint)': \(error)")
                    self.delegate?.didEmitError(error: "Failed to send '\(method)' to '\(endpoint)': \(error)")
                    onComplete(false, nil, error.localizedDescription)
                    return
                }

                print("ℹ 🔗 sent \(method) to '\(endpoint)' successfully")
                onComplete(true, data, nil)
            }
        }.resume()
    }
}
