//
//  ChatModel.swift
//  Stages-demo
//
//  Created by Uldis Zingis on 08/09/2022.
//

import Foundation
import AmazonIVSChatMessaging

class ChatModel: ObservableObject {
    enum MessageType: String {
        case message = "MESSAGE"
    }

    var tokenRequest: ChatTokenRequest?
    var room: ChatRoom?

    @Published var messages: [ChatMessage] = []

    func connectChatRoom(_ chatTokenRequest: ChatTokenRequest, onError: @escaping (String?) -> Void) {
        print("ℹ Connecting to chat room \(chatTokenRequest.chatRoomId)")
        tokenRequest = chatTokenRequest
        room = nil
        room = ChatRoom(awsRegion: chatTokenRequest.awsRegion) {
            return ChatToken(token: chatTokenRequest.chatRoomToken.token)
        }
        room?.delegate = self

        Task(priority: .background) {
            room?.connect({ _, error in
                if let error = error {
                    print("❌ Could not connect to chat room: \(error)")
                    onError(error.localizedDescription)
                }
            })
        }
    }

    func disconnect() {
        room?.disconnect()
        DispatchQueue.main.async {
            self.messages = []
        }
    }

    func sendMessage(_ message: String, user: User, onComplete: @escaping (String?) -> Void) {
        let sendRequest = SendMessageRequest(content: message,
                                             attributes: [
                                                "type": MessageType.message.rawValue,
                                                "username": user.username ?? "",
                                                "avatarUrl": user.avatarUrl ?? ""
                                             ])
        room?.sendMessage(with: sendRequest,
                          onSuccess: { responseType in
            onComplete(nil)
        },
                          onFailure: { chatError in
            print("❌ Error sending message: \(chatError)")
            onComplete(chatError.localizedDescription)
        })
    }

    private func sendChatRequest(_ type: MessageType, connectionId: String, onComplete: @escaping (String?) -> Void) {
        let request = SendMessageRequest(content: type.rawValue,
                                             attributes: ["type": type.rawValue,
                                                          "connectionId": "\(connectionId)"])
        room?.sendMessage(with: request,
                          onSuccess: { responseType in
            onComplete(nil)
        },
                          onFailure: { chatError in
            print("❌ Error sending request to join stage: \(chatError)")
            onComplete(chatError.localizedDescription)
        })
    }
}

extension ChatModel: ChatRoomDelegate {
    func roomDidConnect(_ room: ChatRoom) {
        print("ℹ Did connect to chat room \(room)")
    }

    func roomDidDisconnect(_ room: ChatRoom) {
        print("ℹ Did disconnect from chat room \(room)")
    }

    func room(_ room: ChatRoom, didReceive message: ChatMessage) {
        print("ℹ Chat did receive message: \(message.content), attributes: \(message.attributes ?? [:])")
        guard let type = message.attributes?["type"] else {
            print("❌ No message 'type' in message attributes: \(message.attributes ?? [:])")
            return
        }
        let messageType = MessageType(rawValue: type)

        DispatchQueue.main.async {
            switch messageType {
                case .message:
                    self.messages.append(message)
                    // Store only last 50 messages
                    if self.messages.count > 50 {
                        self.messages.remove(at: 0)
                    }
                case .none:
                    print("❌ None message type received")
            }
        }
    }

    func room(_ room: ChatRoom, didReceive event: ChatEvent) {
        print("ℹ Chat did receive event: \(event)")
    }
}
