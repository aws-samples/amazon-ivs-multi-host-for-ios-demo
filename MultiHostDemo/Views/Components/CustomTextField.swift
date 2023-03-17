//
//  CustomTextField.swift
//  Multihost
//
//  Created by Uldis Zingis on 22/07/2022.
//

import SwiftUI

struct CustomTextField: UIViewRepresentable {
    @Binding public var text: String
    let onCommit: () -> Void

    public init(text: Binding<String>, onCommit: @escaping () -> Void) {
        self.onCommit = onCommit
        self._text = text
    }

    public func makeUIView(context: Context) -> UITextField {
        let view = TextField()
        view.returnKeyType = .send
        view.textColor = .white
        view.font = UIFont.systemFont(ofSize: 15)
        view.addTarget(context.coordinator, action: #selector(Coordinator.textViewDidChange), for: .editingChanged)
        view.delegate = context.coordinator
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.textAlignment = .left
        return view
    }

    public func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator($text, onCommit: onCommit)
    }

    public class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        var onCommit: () -> Void

        init(_ text: Binding<String>, onCommit: @escaping () -> Void) {
            self.text = text
            self.onCommit = onCommit
        }

        public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onCommit()
            return false
        }

        @objc public func textViewDidChange(_ textField: UITextField) {
            self.text.wrappedValue = textField.text ?? ""
        }
    }
}

class TextField: UITextField {
    let padding = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}
