//
//  SetupView.swift
//  Multihost
//
//  Created by Uldis Zingis on 22/07/2022.
//

import SwiftUI

struct SetupView: View {
    @EnvironmentObject var services: ServicesManager
    @Binding var isPresent: Bool
    @Binding var isLoading: Bool
    @Binding var isStageListPresent: Bool
    var onComplete: (User, String?) -> Void
    @State var username: String = ""
    @State var avatarUrl: String = ""
    @State var joinToken: String = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("Background")
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading) {

                Spacer()

                Text("Introduce yourself")
                    .modifier(InputTitle())
                    .frame(maxHeight: 50)
                CustomTextField(text: $username) {}
                    .placeholder(when: username.isEmpty) {
                        Text("Your name")
                            .font(Constants.fAppRegular)
                            .foregroundColor(Color.gray)
                    }
                    .frame(maxHeight: 20)
                Divider()
                    .background(Color.gray)

                Text("Select avatar")
                    .modifier(InputTitleSmall())
                    .padding(.top, 30)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack() {
                        ForEach(Constants.userAvatarUrls, id: \.self) { url in
                            RemoteImageView(imageURL: url)
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                                .overlay(avatarUrl == url ? Circle().stroke(Color.black, lineWidth: 4) : nil)
                                .overlay(avatarUrl == url ? Circle().stroke(Color("Yellow"), lineWidth: 2) : nil)
                                .padding(.horizontal, 4)
                                .onTapGesture {
                                    avatarUrl = url
                                }
                        }
                    }
                    .frame(maxHeight: 52)
                    .padding(.bottom, 20)
                }

                Button(action: {
                    updateUser()
                    withAnimation {
                        isStageListPresent.toggle()
                    }
                }) {
                    Text("Sign in")
                        .modifier(PrimaryButton())
                }
                .disabled(username.isEmpty)
                .padding(.vertical, 30)
            }
            .blur(radius: isLoading ? 3 : 0)
            .padding(.horizontal, 8)

            if isStageListPresent {
                StageList(isPresent: $isStageListPresent,
                          isLoading: $isLoading,
                          onSelect: joinStage,
                          onCreate: createStage)
                .blur(radius: isLoading ? 3 : 0)
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onDisappear {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onFirstAppear {
            username = services.user.username ?? ""
            avatarUrl = services.user.avatarUrl ?? ""

            checkAVPermissions { granted in
                if !granted {
                    services.viewModel?.appendErrorNotification("No camera/microphone permission granted")
                }
            }
        }
    }

    private func createStage() {
        isLoading = true
        onComplete(updateUser(true), nil)
    }

    private func joinStage(_ stage: StageDetails) {
        isLoading = true
        print("ℹ joining stage: \(stage.stageId)")

        services.viewModel?.getToken(for: stage) { stageJoinResponse, error in
            if let token = stageJoinResponse?.stage.token {
                print("ℹ stage auth successful - got token: \(token)")
                services.server.stageDetails = stage
                services.server.joinedStagePlaybackUrl = services.server.stageHostDetails?.channel.playbackUrl ?? ""
                onComplete(updateUser(), stageJoinResponse?.stage.token.token)
            } else {
                print("❌ Could not join stage - missing stage join token: \(error ?? "\(String(describing: stageJoinResponse))")")
            }
            isLoading = false
        }
    }

    @discardableResult
    private func updateUser(_ asHost: Bool = false) -> User {
        services.user.username = username
        services.user.avatarUrl = avatarUrl
        services.user.isHost = asHost
        UserDefaults.standard.set(services.user.username, forKey: "username")
        UserDefaults.standard.set(services.user.avatarUrl, forKey: "avatar")
        return services.user
    }
}
