//
//  ChatMessagesView.swift
//  Stages-demo
//
//  Created by Uldis Zingis on 09/09/2022.
//

import SwiftUI
import AmazonIVSChatMessaging

struct ChatMessagesView: View {
    @ObservedObject var chatModel: ChatModel

    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading) {
                        ForEach(chatModel.messages, id: \.id) { message in
                                MessageView(message: message)
                        }
                    }
                    .rotationEffect(.radians(.pi))
                    .scaleEffect(x: -1, y: 1, anchor: .center)
                    .animation(.easeInOut(duration: 0.25))
                }
                .rotationEffect(.radians(.pi))
                .scaleEffect(x: -1, y: 1, anchor: .center)
                .onChange(of: chatModel.messages, perform: { _ in
                    guard let lastMessage = chatModel.messages.last else { return }
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                })
            }
        }
    }
}

struct MessageView: View {
    @State var message: ChatMessage
    @State private var offsetY: CGFloat = 50
    @State private var opacity: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MessagePreviewView(message: message)
        }
        .offset(y: offsetY)
        .opacity(opacity)
        .onAppear {
            withAnimation {
                offsetY = 0
                opacity = 1
            }
        }
    }
}

struct MessagePreviewView: View {
    @State var message: ChatMessage

    var body: some View {
        HStack(alignment: .top) {
            if let avatarUrl = message.sender.attributes?["avatarUrl"] {
                RemoteImageView(imageURL: avatarUrl)
                    .frame(width: 40, height: 40)
                    .cornerRadius(42)
                    .padding(.leading, 8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(message.sender.attributes?["username"] ?? "")
                    .font(Constants.fAppRegularBold)
                    .foregroundColor(.white)
                Text(message.content)
                    .font(Constants.fAppRegular)
                    .foregroundColor(.white)
            }
        }
    }
}
