//
//  Smooth.swift
//  Compose
//
//  Created by Max Van den Eynde on 15/7/25.
//

import Combine
import SwiftUI
import Thyme
import Tide

class SmoothModifierModel: ObservableObject {
    weak var thymeScene: ThymeScene?
    var index: Int?

    @Published var smooth: Bool = true {
        didSet {
            guard let thymeScene = thymeScene,
                  let index = index,
                  index < thymeScene.appObjects.count else { return }
            thymeScene.appObjects[index].coreObject.shadeSmooth = smooth
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
        smooth = obj.coreObject.shadeSmooth
    }
}

/// Modifier to smooth or not an object
struct SmoothModifier: Modifier {
    var name: String = "Smoothing"
    var icon: String? = "rotate.3d"
    var keyname: String = "core.smooth"
    var thymeScene: ThymeScene?
    var objectIndex: Int?
    var model: SmoothModifierModel?
    let id: UUID = .init()

    init(thymeScene: ThymeScene?, index: Int?) {
        self.thymeScene = thymeScene
        objectIndex = index
        model = SmoothModifierModel(thymeScene: thymeScene, index: index)
    }

    var interface: any Component {
        ConfigureView {
            Checkbox("Smoothing", value: model!.smooth, onChange: {
                model?.smooth = $0
            })
        }
    }
}
