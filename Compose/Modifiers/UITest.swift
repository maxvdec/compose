//
//  UITest.swift
//  Compose
//
//  Created by Max Van den Eynde on 14/7/25.
//

import Combine
import SwiftUI
import Thyme
import Tide

class UITestModifierModel: ObservableObject {
    @Published var vectorTest: Vector3d = [0, 0, 0]
    @Published var vector4: Vector4d = [0, 0, 0]
    @Published var toggleA: Bool = true
    @Published var toggleB: Bool = false
    @Published var toggleC: Bool = false
}

/// Test modifier for core UI elements
struct UITestModifier: Modifier {
    var thymeScene: Thyme.ThymeScene? = nil
    var objectIndex: Int? = nil

    var name: String = "UI Test"
    var icon: String? = "macwindow"
    var keyname: String = "test.uitest"

    var model: UITestModifierModel = .init()

    var interface: any Component {
        ConfigureView {
            Section(title: "Text") {
                UIText("Hello")
                UIText("I warn you").warning()
                UIText("This is a mistake").error()
                UIText("I feel empty").noBackground()
            }
            Section(title: "Fields") {
                Vector3Input(title: "Hello", value: model.vectorTest, components: ["a", "b", "c"], onChange: { model.vectorTest = $0 })
                Vector4Input(title: "Vector of four", value: model.vector4, components: ["a", "b", "c", "d"], onChange: { model.vector4 = $0 })
            }
            Section(title: "Input") {
                Checkbox("A", value: model.toggleA, onChange: { model.toggleA = $0 }).withStyle(.switcher)
                Checkbox("B", value: model.toggleB, onChange: { model.toggleB = $0 }).withStyle(.switcher)
                Checkbox("C", value: model.toggleC, onChange: { model.toggleC = $0 }).withStyle(.switcher)
            }
        }
    }
}
