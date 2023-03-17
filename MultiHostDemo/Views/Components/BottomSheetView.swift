//
//  BottomSheetView.swift
//  Stages-demo
//
//  Created by Uldis Zingis on 12/10/2022.
//

import Foundation

import SwiftUI

struct BottomSheetView: View {
    @Binding var isPresent: Bool
    var title: String
    var description: String
    var imageUrls: [String] = []
    var onSubmit: () -> Void = {}

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("Background")
                .edgesIgnoringSafeArea(.all)
                .opacity(0.6)

            VStack {
                HStack(spacing: -15) {
                    ForEach(imageUrls, id: \.self) { url in
                        RemoteImageView(imageURL: url.isEmpty ? Constants.userAvatarUrls.randomElement()! : url)
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color("BackgroundLight"), lineWidth: 5))
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 12)

                Text(title)
                    .modifier(Description())

                Text(description)
                    .modifier(TableFooter())
                    .multilineTextAlignment(.center)

                HStack {
                    Button(action: {
                        isPresent.toggle()
                    }) {
                        Text("Ingore")
                            .modifier(ActionButton())
                    }

                    Button(action: {
                        onSubmit()
                        isPresent.toggle()
                    }) {
                        Text("Continue")
                            .modifier(ActionButton(color: Color("Yellow")))
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 50)
            .background(Color("BackgroundLight"))
            .cornerRadius(20)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct ConfirmationBottomSheetView: View {
    @Binding var isPresent: Bool
    var title: String
    var description: String
    var confirmTitle: String
    var confirmColor: Color = Color("Red")
    var declineTitle: String = "Cancel"
    var onConfirm: () -> Void = {}
    var onDecline: () -> Void = {}

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("Background")
                .edgesIgnoringSafeArea(.all)
                .opacity(0.6)

            VStack {
                Text(title)
                    .modifier(Title())

                Text(description)
                    .modifier(Description())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                HStack {
                    Button(action: {
                        onConfirm()
                        isPresent.toggle()
                    }) {
                        Text(confirmTitle)
                            .modifier(ActionButton(color: confirmColor))
                    }

                    Button(action: {
                        onDecline()
                        isPresent.toggle()
                    }) {
                        Text(declineTitle)
                            .modifier(ActionButton())
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 50)
            .background(Color("BackgroundLight"))
            .cornerRadius(20)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
