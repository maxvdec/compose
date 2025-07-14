//
//  Transform.swift
//  Compose
//
//  Created by Max Van den Eynde on 14/7/25.
//

/// Transform modifier to change scale, position and rotation
struct TransformModifier: Modifier {
    var name: String = "Transform"
    var icon: String? = "move.3d"
    var keyname: String = "core.transform"
    var interface: any Component {
        ConfigureView {
            UIText("Hello")
        }
    }
}
