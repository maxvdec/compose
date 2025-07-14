//
//  UITest.swift
//  Compose
//
//  Created by Max Van den Eynde on 14/7/25.
//

/// Test modifier for core UI elements
struct UITestModifier: Modifier {
    var name: String = "UI Test"
    var icon: String? = "macwindow"
    var keyname: String = "test.uitest"
    var interface: any Component {
        ConfigureView {
            UIText("Hello")
        }
    }
}
