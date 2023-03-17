
//  ParticipantsGridView.swift
//  Multihost
//
//  Created by Uldis Zingis on 09/06/2022.
//

import SwiftUI
import AmazonIVSBroadcast

struct ParticipantsGridView: View {
    @ObservedObject var viewModel: StageViewModel

    var body: some View {
        if viewModel.sessionRunning {
            switch viewModel.participantCount {
                case 0:
                    EmptyView()
                case 1:
                    viewModel.participantsData[0].previewView
                case 2:
                    VStack {
                        viewModel.participantsData[0].previewView.cornerRadius(40)
                        viewModel.participantsData[1].previewView.cornerRadius(40)
                    }
                case 3:
                    VStack {
                        viewModel.participantsData[0].previewView.cornerRadius(40)
                        HStack {
                            viewModel.participantsData[1].previewView.cornerRadius(40)
                            viewModel.participantsData[2].previewView.cornerRadius(40)
                        }
                    }
                default:
                    VStack {
                        HStack {
                            viewModel.participantsData[0].previewView.cornerRadius(40)
                            viewModel.participantsData[1].previewView.cornerRadius(40)
                        }
                        HStack {
                            viewModel.participantsData[2].previewView.cornerRadius(40)
                            viewModel.participantsData[3].previewView.cornerRadius(40)
                        }
                    }
            }
        } else {
            Spacer()
        }
    }
}
