//
//  Transform.swift
//  Compose
//
//  Created by Max Van den Eynde on 14/7/25.
//

import Combine
import Thyme
import Tide

class TransformModifierModel: ObservableObject {
    @Published var position: Vector3d = [0, 0, 0]
    @Published var rotation: Vector3d = [0, 0, 0]
    @Published var scale: Vector3d = [1, 1, 1]
}

/// Transform modifier to change scale, position and rotation
struct TransformModifier: Modifier {
    var name: String = "Transform"
    var icon: String? = "move.3d"
    var keyname: String = "core.transform"
    var model: TransformModifierModel = .init()
    
    var thymeObject: Tide.Object<Thyme.CoreObject>?
    
    init(thymeObject: Object<CoreObject>? = nil) {
        self.thymeObject = thymeObject
    }

    var interface: any Component {
        ConfigureView {
            Vector3Input(title: "Position", value: model.position, components: ["x", "y", "z"], onChange: { newValue in model.position = newValue })
            Vector3Input(title: "Rotation", value: model.rotation, components: ["x", "y", "z"], onChange: { newValue in model.rotation = newValue }, units: "º")
            Vector3Input(title: "Scale", value: model.scale, components: ["x", "y", "z"], onChange: { newValue in model.scale = newValue })
        }
    }
}
