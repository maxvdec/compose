//
//  Shared.swift
//  Compose
//
//  Created by Max Van den Eynde on 12/7/25.
//

import Metal
import MetalKit

class Shared {
    nonisolated(unsafe) static let properties: Shared = .init()

    var device: MTLDevice!

    private init() {
        device = MTLCreateSystemDefaultDevice()!
    }
}
