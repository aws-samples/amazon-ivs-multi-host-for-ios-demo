//
//  NotificationsView.swift
//  Multihost
//
//  Created by Uldis Zingis on 26/07/2022.
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var services: ServicesManager
    @ObservedObject var viewModel: StageViewModel
    @State private var scrollViewContentSize: CGFloat = 0

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                ForEach(viewModel.notifications, id: \.id, content: { notification in
                    VStack(alignment: .leading) {
                        HStack {
                            Image(notification.iconName)
                                .resizable()
                                .frame(width: 15, height: 15)
                            Text(notification.title)
                                .opacity(0.6)
                                .font(Constants.fAppSmall)
                        }
                        .padding(.top, 10)

                        Text(notification.message)
                            .font(Constants.fAppRegular)
                            .padding(.bottom, 10)
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor([.success, .error].contains(notification.type) ? Color.white : Color.black)
                    .background(colorFor(notification.type))
                    .cornerRadius(8)
                    .onTapGesture {
                        viewModel.removeNotification(notification)
                    }
                })
                .background(
                    GeometryReader { geo -> Color in
                        DispatchQueue.main.async {
                            scrollViewContentSize = geo.size.height
                        }
                        return Color.clear
                    }
                )
            }
            .frame(maxHeight: scrollViewContentSize)
            .onChange(of: viewModel.notifications) { _ in
                proxy.scrollTo(viewModel.notifications.last?.id)
            }
        }
    }

    func colorFor(_ type: NotificationType) -> Color {
        switch type {
            case .success:
                return Color("Green")
            case .error:
                return Color("Red")
            case .warning:
                return Color("Yellow")
            case .blank:
                return Color.white
        }
    }
}
