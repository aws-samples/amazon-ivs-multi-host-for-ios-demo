//
//  StageListView.swift
//  Stages-demo
//
//  Created by Uldis Zingis on 10/11/2022.
//

import SwiftUI

struct StageList: View {
    @EnvironmentObject var services: ServicesManager
    @Binding var isPresent: Bool
    @Binding var isLoading: Bool
    @State var stages: [StageDetails] = []
    @State var isCameraPreviewPresent: Bool = false
    @State var selectedStage: StageDetails?
    var onSelect: (StageDetails) -> Void
    var onCreate: () -> Void

    var body: some View {
        UIRefreshControl.appearance().tintColor = UIColor.white
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UIRefreshControl.appearance().attributedTitle = NSAttributedString(string: "Loading", attributes: attributes)
        UIScrollView.appearance().backgroundColor = UIColor.clear
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear

        let list = List(stages, id: \.stageId) { stage in
            if stages.count == 1 && stage.stageId.isEmpty {
                EmptyView()
                    .background(Color.clear)
            } else {
                VStack(spacing: 0) {
                    Divider()
                        .background(Color("TextGray1"))
                        .opacity(0.5)
                    HStack {
                        RemoteImageView(imageURL: stage.userAttributes.avatarUrl)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())

                        Text("\(stage.userAttributes.username)'s Stage")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.white)
                            .font(Constants.fAppRegular)
                            .padding(.horizontal, 16)

                        Spacer()
                    }
                    .frame(height: 55)
                    .padding(.horizontal, 16)
                    .onTapGesture {
                        selectedStage = stage
                        isCameraPreviewPresent = true
                    }
                }
                .listRowBackground(Color("BackgroundList"))
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0,
                                          leading: 0,
                                          bottom: 0,
                                          trailing: 0))
            }
        }
            .overlay(alignment: .center) {
                if stages.first?.stageId.isEmpty ?? true {
                    Text("No stages are available\n Create a new stage to get started.")
                        .modifier(Description())
                }
            }
            .background(Color.clear)
            .listStyle(.plain)
            .refreshable(action: {
                services.viewModel?.getAllStages { allStages in
                    stages = allStages
                }
            })
            .preferredColorScheme(.dark)

        return ZStack(alignment: .top) {
            Color("Background")
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading, spacing: 0) {
                Text("Stages")
                    .modifier(TitleLeading())

                if !(stages.first?.stageId.isEmpty ?? false) {
                    Text("All stages")
                        .modifier(TableHeader())
                }

                if #available(iOS 16.0, *) {
                    list
                        .scrollContentBackground(.hidden)
                } else {
                    list
                }

                Spacer()

                Button(action: {
                    onCreate()
                }) {
                    Text("Create new stage")
                        .modifier(PrimaryButton())
                }
                .padding(.top, 30)
            }

            if isCameraPreviewPresent, let viewModel = services.viewModel {
                JoinPreviewView(viewModel: viewModel, isPresent: $isCameraPreviewPresent, isLoading: $isLoading) {
                    guard let stage = selectedStage else {
                        print("❌ Can't join - no stage selected")
                        return
                    }
                    isPresent = false
                    onSelect(stage)
                }
            }
        }
        .onAppear {
            isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                services.viewModel?.getAllStages(initial: true) { allStages in
                    stages = allStages
                    isLoading = false
                }
            }
        }
    }
}
