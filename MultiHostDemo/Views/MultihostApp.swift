//
//  MultihostApp.swift
//  Multihost
//
//  Created by Uldis Zingis on 09/06/2022.
//

import SwiftUI

@main
struct MultihostApp: App {
    @ObservedObject var services = ServicesManager()
    @State var isWelcomePresent: Bool = true
    @State var isSetupPresent: Bool = false
    @State var isStageListPresent: Bool = false
    @State var isStagePresent: Bool = false
    @State var isLoading: Bool = false

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .top) {
                Color("Background")
                    .edgesIgnoringSafeArea(.all)

                if isStagePresent, let viewModel = services.viewModel {
                    StageView(viewModel: viewModel,
                                       chatModel: services.chatModel,
                                       isPresent: $isStagePresent,
                                       isLoading: $isLoading,
                                       backAction: backAction)
                    .transition(.slide)
                }

                if isSetupPresent {
                    SetupView(isPresent: $isSetupPresent,
                              isLoading: $isLoading,
                              isStageListPresent: $isStageListPresent,
                              onComplete: { (user, token) in
                        services.viewModel?.clearNotifications()
                        services.user = user

                        if user.isHost {
                            services.viewModel?.createStage(user: user) { success in
                                if success {
                                    services.viewModel?.initializeStage(onComplete: {
                                        services.viewModel?.joinAsHost() { success in
                                            if success {
                                                presentStage()
                                            }
                                            isLoading = false
                                        }
                                    })
                                } else {
                                    isLoading = false
                                }
                            }
                        } else if let token = token {
                            services.viewModel?.initializeStage(onComplete: {
                                services.viewModel?.joinAsParticipant(token) {
                                    presentStage()
                                    isLoading = false
                                }
                            })
                        }
                    })
                }

                if isWelcomePresent {
                    WelcomeView(isPresent: $isWelcomePresent,
                                isSetupPresent: $isSetupPresent)
                }

                if let viewModel = services.viewModel {
                    NotificationsView(viewModel: viewModel)
                }

                if isLoading {
                    ActivityIndicator()
                }
            }
            .environmentObject(services)
        }
    }

    private func presentStage() {
        withAnimation {
            isStagePresent = true
        }
        isSetupPresent = !isStagePresent
        isWelcomePresent = !isStagePresent
    }

    private func backAction() {
        isSetupPresent = true
        isStageListPresent = true
        withAnimation {
            isStagePresent = false
        }
        isLoading = false
    }
}
