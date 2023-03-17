//
//  ChatTokenRequest.swift
//  Stages-demo
//
//  Created by Uldis Zingis on 08/09/2022.
//

import Foundation

struct ChatAuthToken: Decodable {
    let token: String
    let sessionExpirationTime: String
    let tokenExpirationTime: String
}

struct ChatTokenRequest: Codable {
    enum UserCapability: String, Codable {
        case deleteMessage = "DELETE_MESSAGE"
        case disconnectUser = "DISCONNECT_USER"
        case sendMessage = "SEND_MESSAGE"
    }

    enum TokenRequestError: Error {
        case serverNotSet
    }

    let user: User
    let chatRoomId: String
    let chatRoomToken: ChatTokenData

    var awsRegion: String {
        chatRoomId.components(separatedBy: ":")[3]
    }

    func fetchResponse() async throws -> Data {
        print("ℹ Requesting new chat auth token")
        guard let url = URL(string: "\(Constants.API_URL)/chat/auth") else {
            print("❌ Server url not set in Constats.swift")
            throw TokenRequestError.serverNotSet
        }
        let authSession = URLSession(configuration: .default)
        var authRequest = URLRequest(url: url)
        authRequest.httpMethod = "POST"
        authRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        authRequest.httpBody = """
            {
                "roomIdentifier": "\(chatRoomId)",
                "userId": "\(user.userId)",
                "attributes": {
                    "username": "\(user.username ?? "")",
                    "avatar": "\(user.avatarUrl ?? "")"
                },
                "capabilities": ["\(UserCapability.sendMessage.rawValue)"],
                "durationInMinutes": 55
            }
        """.data(using: .utf8)
        authRequest.timeoutInterval = 10

        return try await authSession.data(for: authRequest).0
    }
}
