//
//  Notification.swift
//  Multihost
//
//  Created by Uldis Zingis on 27/07/2022.
//

import Foundation

enum NotificationType: String {
    case success, error, warning, blank
}

struct Notification: Hashable {
    let id: String
    let type: NotificationType
    let message: String
    let title: String
    let iconName: String

    init(type: NotificationType, message: String) {
        self.id = UUID().uuidString
        self.type = type
        self.message = message
        self.title = type.rawValue.uppercased()
        self.iconName = Notification.iconNameFor(type)
    }

    private static func iconNameFor(_ type: NotificationType) -> String {
        switch type {
            case .success:
                return "icon_info_light"
            case .error:
                return "icon_warning"
            case .warning:
                return "icon_info_dark"
            case .blank:
                return "icon_info_dark"
        }
    }
}
