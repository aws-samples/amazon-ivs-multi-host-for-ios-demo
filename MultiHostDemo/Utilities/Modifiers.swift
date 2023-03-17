//
//  Modifiers.swift
//  Multihost
//
//  Created by Uldis Zingis on 22/07/2022.
//

import SwiftUI

struct PrimaryButton: ViewModifier {
    @Environment(\.isEnabled) var isEnabled
    var color: Color = Color("Yellow")
    var textColor: Color = .black

    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundColor(textColor)
            .font(Constants.fAppPrimary)
            .background(isEnabled ? color : Color.gray)
            .cornerRadius(8)
    }
}

struct SecondaryButton: ViewModifier {
    @Environment(\.isEnabled) var isEnabled

    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundColor(isEnabled ? Color("Yellow") : Color.gray)
            .font(Constants.fAppSecondary)
    }
}

struct ActionButton: ViewModifier {
    @Environment(\.isEnabled) var isEnabled
    var color: Color = .white
    var background: Color = Color("BackgroundList")

    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .foregroundColor(isEnabled ? color : .gray)
            .font(Constants.fAppSecondaryMedium)
            .background(background)
            .cornerRadius(8)
    }
}

struct Title: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .multilineTextAlignment(.center)
            .font(Constants.fAppTitle)
            .foregroundColor(.white)
    }
}

struct TitleLeading: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .font(Constants.fAppTitle)
            .foregroundColor(.white)
    }
}

struct TitleRegular: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .multilineTextAlignment(.center)
            .font(Constants.fAppPrimaryRegular)
            .foregroundColor(.white)
    }
}

struct Subtitle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .font(Constants.fAppSmallMedium)
            .foregroundColor(Color("TextGray2"))
    }
}

struct Description: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .font(Constants.fAppRegular)
            .foregroundColor(.white)
    }
}

struct InputTitle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(.vertical, 6)
            .font(Constants.fAppPrimary)
            .foregroundColor(.white)
    }
}

struct InputTitleSmall: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(.vertical, 6)
            .font(Constants.fAppPrimarySmall)
            .foregroundColor(.white)
    }
}

struct TableHeader: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(Constants.fAppTitleSmall)
            .foregroundColor(Color("TextGray1"))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }
}

struct TableFooter: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(Constants.fAppSmall)
            .foregroundColor(Color("TextGray2"))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }
}
