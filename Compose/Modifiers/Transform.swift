//
//  Transform.swift
//  Compose
//
//  Created by Max Van den Eynde on 14/7/25.
//

import Combine
import SwiftUI
import Thyme
import Tide

class TransformModifierModel: ObservableObject {
    weak var thymeScene: ThymeScene?
    var index: Int?

    @Published var position: Vector3d = [0, 0, 0] {
        didSet {
            guard let thymeScene = thymeScene,
                  let index = index,
                  index < thymeScene.appObjects.count else { return }
            thymeScene.appObjects[index].coreObject.position = position
        }
    }

    @Published var rotation: Rotation3d = [0, 0, 0] {
        didSet {
            guard let thymeScene = thymeScene,
                  let index = index,
                  index < thymeScene.appObjects.count else { return }
            thymeScene.appObjects[index].coreObject.rotation = rotation
        }
    }

    @Published var scale: Size3d = [1, 1, 1] {
        didSet {
            guard let thymeScene = thymeScene,
                  let index = index,
                  index < thymeScene.appObjects.count else { return }
            thymeScene.appObjects[index].coreObject.scale = scale
        }
    }

    init(thymeScene: ThymeScene?, index: Int?) {
        self.thymeScene = thymeScene
        self.index = index

        guard let thymeScene = thymeScene,
              let index = index
        else {
            self.thymeScene = nil
            self.index = nil
            return
        }
        
        if thymeScene.appObjects.isEmpty {
            return
        }

        let obj = thymeScene.appObjects[index]
        position = obj.coreObject.position
        rotation = obj.coreObject.rotation
        scale = obj.coreObject.scale
    }
}

/// Transform modifier to change scale, position and rotation
struct TransformModifier: Modifier {
    var name: String = "Transform"
    var icon: String? = "move.3d"
    var keyname: String = "core.transform"
    var thymeScene: ThymeScene?
    var objectIndex: Int?
    var model: TransformModifierModel?

    init(thymeScene: ThymeScene?, index: Int?) {
        self.thymeScene = thymeScene
        objectIndex = index
        model = TransformModifierModel(thymeScene: thymeScene, index: index)
    }

    var interface: any Component {
        ConfigureView {
            Vector3Input(title: "Position", value: model?.position ?? [0, 0, 0], components: ["x", "y", "z"], onChange: { newValue in
                model?.position = newValue
            })
            Vector3Input(title: "Rotation", value: model?.rotation ?? [0, 0, 0], components: ["x", "y", "z"], onChange: { newValue in
                model?.rotation = newValue
            }, units: "º")
            Vector3Input(title: "Scale", value: model?.scale ?? [1, 1, 1], components: ["x", "y", "z"], onChange: { newValue in
                model?.scale = newValue
            })
        }
    }
}
