//
//  Stage.swift
//  Multihost
//
//  Created by Uldis Zingis on 29/07/2022.
//

import Foundation

struct StageHostDetails: Decodable {
    let groupId: String
    let channel: Channel
    let stage: Stage
    let chat: Chat
}

struct StageJoinDetails: Decodable {
    let stage: Stage
    let chat: Chat
}

struct Stage: Decodable {
    let id: String
    let token: StageTokenData
}

struct Chat: Decodable {
    let id: String
    let token: ChatTokenData
}

struct StageTokenData: Decodable {
    let token: String
    let participantId: String
    let expirationTime: String
}

struct ChatTokenData: Codable {
    let token: String
    let sessionExpirationTime: String?
    let tokenExpirationTime: String?
}

struct StageDetails: Decodable {
    let roomId: String
    let channelId: String
    let userAttributes: UserAttributes
    let groupId: String
    let stageId: String

    enum CodingKeys: String, CodingKey {
        case roomId
        case channelId
        case stageId
        case groupId
        case userAttributes = "stageAttributes"
    }

    static let empty = StageDetails(
        roomId: "",
        channelId: "",
        userAttributes: UserAttributes(username: "", avatarUrl: ""),
        groupId: "",
        stageId: "")
}

struct UserAttributes: Decodable {
    let username: String
    let avatarUrl: String
}

struct Channel: Decodable {
    let id: String
    let playbackUrl: String
    let ingestEndpoint: String
    let streamKey: String
}

struct StreamKey: Decodable {
    let arn: String
    let channelArn: String
    let value: String
}
