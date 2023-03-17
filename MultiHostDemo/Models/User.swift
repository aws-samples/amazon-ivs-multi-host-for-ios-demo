//
//  User.swift
//  Multihost
//
//  Created by Uldis Zingis on 25/07/2022.
//

import Foundation

class User: ObservableObject, Codable, Hashable {
    var userId: String
    var username: String?
    var avatarUrl: String?
    var participantId: String?
    var isHost: Bool = false
    @Published var videoOn: Bool = true
    @Published var audioOn: Bool = true

    init(username: String, avatarUrl: String, isHost: Bool = false) {
        self.userId = UUID().uuidString
        self.username = username
        self.avatarUrl = avatarUrl
        self.isHost = isHost
    }

    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.userId == rhs.userId && lhs.username == rhs.username
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(username)
        hasher.combine(avatarUrl)
        hasher.combine(isHost)
        hasher.combine(userId)
    }

    required init(from decoder: Decoder) throws {
        self.userId = UUID().uuidString
        let container = try decoder.container(keyedBy: CodingKeys.self)
        videoOn = try container.decode(Bool.self, forKey: .videoOn)
        audioOn = try container.decode(Bool.self, forKey: .audioOn)
        username = try container.decode(String.self, forKey: .username)
        avatarUrl = try container.decode(String.self, forKey: .avatarUrl)
        participantId = try container.decode(String.self, forKey: .participantId)
        isHost = try container.decode(Bool.self, forKey: .isHost)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(videoOn, forKey: .videoOn)
        try container.encode(audioOn, forKey: .audioOn)
    }

    enum CodingKeys: CodingKey {
        case isHost, participantId, avatarUrl, username, audioOn, videoOn
    }
}
