//
//  ManageParticipantsView.swift
//  Multihost
//
//  Created by Uldis Zingis on 10/08/2022.
//

import SwiftUI

struct ManageParticipantsView: View {
    @EnvironmentObject var services: ServicesManager
    @Binding var isPresent: Bool
    @State var confirmationPresent: Bool = false

    @State var confirmationTitle: String = ""
    @State var confirmationDescription: String = ""
    @State var confirmationConfirmTitle: String = ""
    @State var confirmAction: () -> Void = {}

    private func presentConfirmation(title: String, description: String , confirmTitle: String, action: @escaping () -> Void) {
        confirmationTitle = title
        confirmationDescription = description
        confirmationConfirmTitle = confirmTitle
        confirmAction = action
        confirmationPresent = true
    }

    var body: some View {
        ZStack {
            if (confirmationPresent) {
                ConfirmationBottomSheetView(
                    isPresent: $confirmationPresent,
                    title: confirmationTitle,
                    description: confirmationDescription,
                    confirmTitle: confirmationConfirmTitle,
                    onConfirm: confirmAction)
            } else {
                GeometryReader { (proxy: GeometryProxy) in
                    ZStack(alignment: .bottom) {
                        Color.black
                            .edgesIgnoringSafeArea(.all)
                            .opacity(0.4)
                            .onTapGesture {
                                isPresent.toggle()
                            }

                        VStack {
                            HStack {
                                Button {
                                    isPresent.toggle()
                                } label: {
                                    Image(systemName: "xmark")
                                        .resizable()
                                        .frame(width: 12, height: 12)
                                        .foregroundColor(Color.white)
                                }
                                Spacer()
                                Text("Stage Participants")
                                    .modifier(InputTitle())
                                Spacer()
                            }
                            .padding(16)

                            ManageParticipantListView(
                                viewModel: services.viewModel!,
                                onRemoveAction: { participant in
                                    presentConfirmation(
                                        title: "Confirm removal",
                                        description: "Continue removing \(participant.username) from the stage?",
                                        confirmTitle: "Yes, remove") {
                                            services.viewModel?.kick(participant.participantId ?? participant.id)
                                            isPresent.toggle()
                                        }
                                }
                            )

                            if services.viewModel?.participantCount == 0 {
                                Text("No participants")
                                    .modifier(TableFooter())
                                    .padding(.bottom, 50)
                            }

                            Spacer()
                        }
                        .frame(width: proxy.size.width)
                        .frame(maxHeight: 400)
                        .background(Color("BackgroundLight"))
                        .cornerRadius(20)
                        .padding(.bottom, -25)
                    }
                }
            }
        }
    }
}

struct ManageParticipantListView: View {
    @EnvironmentObject var services: ServicesManager
    @ObservedObject var viewModel: StageViewModel
    var onRemoveAction: (ParticipantData) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.participantsData, id: \.id) { participant in
                Divider()
                    .background(Color("TextGray1"))
                    .opacity(0.5)
                HStack(spacing: 4) {
                    RemoteImageView(imageURL: participant.avatarUrl)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .padding(.leading, 16)

                    Text(participant.username + "\(participant.isLocal ? " (You)" : "")")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(Color.white)
                        .font(Constants.fAppSmall)
                        .background(Color("BackgroundList"))
                        .padding(.horizontal, 16)

                    Spacer()

                    HStack(spacing: 20) {
                        Button {
                            if participant.isLocal {
                                viewModel.toggleLocalAudioMute()
                            } else {
                                viewModel.toggleRemoteAudioMute(for: participant.participantId)
                            }
                        } label: {
                            Image((participant.isLocal && viewModel.localUserAudioMuted) || participant.audioMuted ?
                                  "icon_mic_off_red" : "icon_mic_on")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(Color.white)
                        }

                        Button {
                            if participant.isLocal {
                                viewModel.toggleLocalVideoMute()
                            } else {
                                viewModel.toggleRemoteVideoMute(for: participant.participantId)
                            }
                        } label: {
                            Image((participant.isLocal && viewModel.localUserVideoMuted) || participant.videoMuted ? "icon_video_off_red" : "icon_video_on")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(Color.white)
                        }

                        if services.user.isHost && !participant.isLocal {
                            Button {
                                onRemoveAction(participant)
                            } label: {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(Color("Red"))
                            }
                        }
                    }
                    .padding(.trailing, 16)
                }
                .frame(height: 55)
            }
            .background(Color("BackgroundList"))
        }
        .padding(.bottom, 50)
    }
}
