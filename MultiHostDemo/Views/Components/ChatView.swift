//
//  ChatView.swift
//  Stages-demo
//
//  Created by Uldis Zingis on 05/09/2022.
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var services: ServicesManager
    @ObservedObject var chatModel: ChatModel
    @Binding var isPresent: Bool
    @State var message: String = ""

    var body: some View {
        ZStack {
            if isPresent {
                VStack(alignment: .center, spacing: 0) {
                    ChatMessagesView(chatModel: chatModel)
                        .frame(maxHeight: 150)

                    HStack {
                        RemoteImageView(imageURL: services.user.avatarUrl ?? "")
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .padding(.leading, 8)

                        CustomTextField(text: $message) {
                            if message.isEmpty {
                                return
                            }
                            chatModel.sendMessage(message, user: services.user, onComplete: { error in
                                if let error = error {
                                    services.viewModel?.appendErrorNotification(error)
                                } else {
                                    message = ""
                                }
                            })
                        }
                        .padding(.horizontal, 8)
                        .placeholder(when: message.isEmpty, alignment: .leading) {
                            Text("Say something...")
                                .font(Constants.fAppRegular)
                                .foregroundColor(.white)
                                .padding(.leading, 10)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color("BackgroundSecondary"))
                        .cornerRadius(20)
                        .padding(.horizontal, 8)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                .background(LinearGradient(gradient: Gradient(colors: [.clear, Color("GradientGray")]),
                                           startPoint: .top,
                                           endPoint: .bottom))
            }
        }
    }
}
