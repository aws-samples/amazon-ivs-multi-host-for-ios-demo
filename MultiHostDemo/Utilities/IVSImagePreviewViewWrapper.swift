//
//  IVSImagePreviewViewWrapper.swift
//  Stages-demo
//
//  Created by Uldis Zingis on 02/09/2022.
//

import SwiftUI
import AmazonIVSBroadcast

struct IVSImagePreviewViewWrapper: UIViewRepresentable {
    let previewView: IVSImagePreviewView?

    func makeUIView(context: Context) -> IVSImagePreviewView {
        guard let view = previewView else {
            fatalError("No actual IVSImagePreviewView passed to wrapper")
        }
        return view
    }

    func updateUIView(_ uiView: IVSImagePreviewView, context: Context) {}
}
