//
//  UITest.swift
//  Compose
//
//  Created by Max Van den Eynde on 14/7/25.
//

import Combine
import SwiftUI
import Tide

class UITestModifierModel: ObservableObject {
    @Published var vectorTest: Vector3d = [0, 0, 0]
    @Published var vector4: Vector4d = [0, 0, 0]
}

/// Test modifier for core UI elements
struct UITestModifier: Modifier {
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
        }
    }
}
