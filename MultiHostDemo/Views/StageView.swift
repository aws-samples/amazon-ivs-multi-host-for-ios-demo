//
//  BroadcastView.swift
//  Multihost
//
//  Created by Uldis Zingis on 09/06/2022.
//

import SwiftUI

struct StageView: View {
    @EnvironmentObject var services: ServicesManager
    @ObservedObject var viewModel: StageViewModel
    @ObservedObject var chatModel: ChatModel
    @Binding var isPresent: Bool
    @Binding var isLoading: Bool
    var backAction: () -> Void

    @State var isControlsExpanded: Bool = false
    @State var isManageParticipantsPresent: Bool = false
    @State var isChatPresent: Bool = false
    @State var isParticipantRequestToJoinPresent: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            Color("Background")
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .center, spacing: 0) {
                HeaderView(isLoading: $isLoading,
                           isManageParticipantsPresent: $isManageParticipantsPresent,
                           backAction: backAction)

                ZStack(alignment: .bottom) {
                    if let viewModel = services.viewModel {
                        ParticipantsGridView(viewModel: viewModel)
                            .onTapGesture {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                                to: nil, from: nil, for: nil)
                                withAnimation {
                                    isControlsExpanded = false
                                }
                            }
                            .cornerRadius(40)
                            .padding(.bottom, 80)
                    }

                    ChatView(chatModel: services.chatModel, isPresent: $isChatPresent)
                        .padding(.bottom, 80)

                    ControlButtonsDrawer(viewModel: services.viewModel!,
                                         isExpanded: $isControlsExpanded,
                                         isChatPresent: $isChatPresent)
                        .padding(.bottom, !isControlsExpanded && services.user.isHost ? -145 : 0)
                        .onTapGesture {
                            guard !isControlsExpanded else { return }
                            withAnimation {
                                isControlsExpanded = true
                            }
                        }
                }

            }
            .frame(alignment: .bottom)
            .navigationBarBackButtonHidden(true)

            if isManageParticipantsPresent {
                ManageParticipantsView(isPresent: $isManageParticipantsPresent)
            }
        }
        .onAppear {
            isChatPresent = !services.user.isHost
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onChange(of: viewModel.stageConnectionState) { state in
            if state == .disconnected {
                backAction()
            }
        }
    }
}

struct HeaderView: View {
    @EnvironmentObject var services: ServicesManager
    @Binding var isLoading: Bool
    @Binding var isManageParticipantsPresent: Bool
    var backAction: () -> Void

    var body: some View {
        HStack {
            Button {
                isLoading = true
                services.disconnectFromStage() {
                    backAction()
                }
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .frame(width: 12, height: 12)
            }
            .foregroundColor(Color.white)
            .padding()
            .frame(width: 50)

            Spacer()

            Text(services.user.isHost ?
                    "Your Stage" :
                    "\(services.server.stageDetails?.userAttributes.username ?? "")'s Stage")
            .modifier(TitleRegular())

            Spacer()

            ControlButton(image: Image("icon_group"),
                          backgroundColor: Color.clear) {
                isManageParticipantsPresent.toggle()
            }
            .frame(width: 50)
        }
    }
}
