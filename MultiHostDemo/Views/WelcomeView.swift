//
//  WelcomeView.swift
//  Multihost
//
//  Created by Uldis Zingis on 22/07/2022.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var services: ServicesManager
    @Binding var isPresent: Bool
    @Binding var isSetupPresent: Bool

    var body: some View {
        ZStack(alignment: .top) {
            Color("Background")
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .center) {

                Spacer()

                Image("welcomeImage")
                    .resizable()
                    .frame(width: 82, height: 152)

                Spacer()

                Text("Amazon IVS Stages Demo")
                    .modifier(Title())

                Text("This demo app demonstrates how to use Amazon IVS Stages to broadcast a video call.")
                    .modifier(Description())

                Spacer()

                Button(action: {
                    isPresent.toggle()
                    isSetupPresent.toggle()
                }) {
                    Text("Get Started")
                        .modifier(PrimaryButton())
                }
                .padding(.horizontal, 8)

                Link("View Source Code", destination: URL(string: Constants.sourceCodeUrl)!)
                    .modifier(SecondaryButton())
            }
        }
    }
}
