//
//  JoinPreviewView.swift
//  Multihost
//
//  Created by Uldis Zingis on 08/08/2022.
//

import SwiftUI

struct JoinPreviewView: View {
    @EnvironmentObject var services: ServicesManager
    @ObservedObject var viewModel: StageViewModel
    @Binding var isPresent: Bool
    @Binding var isLoading: Bool
    let onJoin: () -> Void

    @State var isPreviewActive: Bool = true
    @State var isFrontCameraActive: Bool = true

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Color("Background")
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.6)

                VStack(spacing: 8) {
                    Text("This is how you'll look and sound")
                        .modifier(Description())
                        .padding(16)

                    CameraView(isPreviewActive: $isPreviewActive, isFrontCameraActive: $isFrontCameraActive)
                        .frame(width: geometry.size.width - 16, height: 400)
                        .scaledToFit()
                        .overlay {
                            ZStack {
                                Color("BackgroundGray")
                                    .cornerRadius(50)

                                VStack(spacing: 0) {
                                    RemoteImageView(imageURL: services.user.avatarUrl ?? "")
                                        .frame(width: 84, height: 84)
                                        .clipShape(Circle())
                                    Text(services.user.username ?? "")
                                        .modifier(TitleRegular())
                                }
                            }
                            .opacity(viewModel.localUserVideoMuted ? 1 : 0)
                            .transition(.opacity.animation(.easeInOut))
                        }
                        .background(Color.black)
                        .cornerRadius(50)
                        .padding(.horizontal, 8)
                        .onAppear {
                            isFrontCameraActive = viewModel.selectedCamera?.position == .front
                        }

                    HStack(spacing: 24) {
                        Spacer()
                        ControlButton(image: Image(viewModel.localUserAudioMuted ? "icon_mic_off" : "icon_mic_on"),
                                      backgroundColor: viewModel.localUserAudioMuted ? .white : Color("BackgroundButton")) {
                            viewModel.toggleLocalAudioMute()
                        }
                        .frame(maxWidth: 48)

                        ControlButton(image: Image(viewModel.localUserVideoMuted ? "icon_video_off" : "icon_video_on"),
                                      backgroundColor: viewModel.localUserVideoMuted ? .white : Color("BackgroundButton")) {
                            withAnimation {
                                viewModel.toggleLocalVideoMute()
                            }
                        }
                        .frame(maxWidth: 48)

                        ControlButton(image: Image("icon_swap_camera")) {
                            viewModel.swapCamera()
                            isFrontCameraActive = !isFrontCameraActive
                        }
                        .frame(maxWidth: 48)
                        Spacer()
                    }
                    .background(Color("BackgroundList"))
                    .cornerRadius(25)
                    .padding(8)

                    HStack {
                        Button(action: {
                            isPresent.toggle()
                        }) {
                            Text("Cancel")
                                .modifier(ActionButton())
                        }

                        Button(action: {
                            isLoading = true
                            isPreviewActive = false

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.onJoin()
                                self.isPresent.toggle()
                            }
                        }) {
                            Text("Join")
                                .modifier(ActionButton(color: .black, background: Color("Yellow")))
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 50)
                .background(Color("BackgroundLight"))
                .cornerRadius(20)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            isPreviewActive = true
        }
    }
}
