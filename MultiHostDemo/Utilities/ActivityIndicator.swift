//
//  ActivityIndicator.swift
//  Multihost
//
//  Created by Uldis Zingis on 01/08/2022.
//

import SwiftUI

struct ActivityIndicator: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Text("")
                    .frame(width: UIScreen.main.bounds.width,
                           height: UIScreen.main.bounds.height,
                           alignment: .center)
                    .background(Color.black.opacity(0.5))

                ProgressView() {
                    Text("Please wait")
                        .modifier(Description())
                }
                .progressViewStyle(CircularProgressViewStyle())
                .foregroundColor(.white)
            }
        }
    }
}
