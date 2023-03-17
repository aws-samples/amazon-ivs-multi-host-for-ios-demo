//
//  Constants.swift
//  Multihost
//
//  Created by Uldis Zingis on 09/06/2022.
//

import SwiftUI

struct Constants {
    static let API_URL = ""

    static let sourceCodeUrl = "https://github.com/aws-samples/amazon-ivs-multi-host-for-ios-demo"

    // Avatar urls for users
    static let userAvatarUrls: [String] = [
        "https://d39ii5l128t5ul.cloudfront.net/assets/animals_square/bear.png",
        "https://d39ii5l128t5ul.cloudfront.net/assets/animals_square/bird.png",
        "https://d39ii5l128t5ul.cloudfront.net/assets/animals_square/bird2.png",
        "https://d39ii5l128t5ul.cloudfront.net/assets/animals_square/giraffe.png",
        "https://d39ii5l128t5ul.cloudfront.net/assets/animals_square/hedgehog.png",
        "https://d39ii5l128t5ul.cloudfront.net/assets/animals_square/hippo.png"
    ]

    // App fonts
    static let fAppRegular = Font.system(size: 15)
    static let fAppRegularBold = Font.system(size: 15, weight: .semibold)
    static let fAppSmall = Font.system(size: 13)
    static let fAppSmallMedium = Font.system(size: 13, weight: .medium)
    static let fAppTitleSmall = Font.system(size: 13, weight: .semibold)
    static let fAppTitle = Font.system(size: 22, weight: .bold)
    static let fAppPrimary = Font.system(size: 17, weight: .bold)
    static let fAppPrimaryRegular = Font.system(size: 17, weight: .regular)
    static let fAppPrimarySmall = Font.system(size: 13, weight: .bold)
    static let fAppSecondary = Font.system(size: 17)
    static let fAppSecondaryMedium = Font.system(size: 17, weight: .medium)

    // Keys
    static let kActiveFrontCamera = "frontCameraIsActive"
}
