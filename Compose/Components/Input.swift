//
//  Input.swift
//  Compose
//
//  Created by Max Van den Eynde on 15/7/25.
//

import Combine
import SwiftUI
import Tide

/// Checkbox that can be either on or off
struct Checkbox: Component {
    var label: String
    var onChange: (Bool) -> Void
    var style: CheckboxStyle = .checkbox
    var value: Bool
    
    /// Style of a checkbox. Maps to SwiftUI internal types
    enum CheckboxStyle {
        case checkbox
        case switcher
        case button
    }

    init(_ label: String, value: Bool, onChange: @escaping (Bool) -> Void, style: CheckboxStyle = .checkbox) {
        self.label = label
        self.onChange = onChange
        self.style = style
        self.value = value
    }

    func render() -> any View {
        AnyView(CheckboxView(label: label, style: style, onChange: onChange, value: value))
    }

    func withStyle(_ style: CheckboxStyle) -> Self {
        var copy = self
        copy.style = style
        return copy
    }

    private struct CheckboxView: View {
        var label: String
        var style: CheckboxStyle
        var onChange: (Bool) -> Void
        var value: Bool
        
        init(label: String, style: CheckboxStyle, onChange: @escaping (Bool) -> Void, value: Bool) {
            self.label = label
            self.style = style
            self.onChange = onChange
            self.value = value
            self._isOn = State(initialValue: value)
            
        }

        @State private var isOn = false

        var body: some View {
            HStack {
                if style == .button {
                    Text(label + ":")
                    Toggle("", isOn: $isOn)
                        .labelsHidden()
                        .toggleStyle(.button)
                } else if style == .checkbox {
                    Text(label + ":")
                    Toggle("", isOn: $isOn)
                        .labelsHidden()
                        .toggleStyle(.checkbox)
                } else {
                    Text(label + ":")
                    Toggle("", isOn: $isOn)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }
            .onChange(of: isOn) { newVal, _ in
                onChange(newVal)
            }
        }
    }
}
