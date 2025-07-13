//
//  Metal.swift
//  Compose
//
//  Created by Max Van den Eynde on 12/7/25.
//

import Metal
import MetalKit
import simd

/// Metal-wise translation of the `CoreVertex` class
struct MetalVertex {
    var position: simd_float3
    var color: simd_float4
    var normals: simd_float3
}

/// Arguments to pass to the metal shader
struct Uniforms {
    var model: simd_float4x4 = .init()
    var view: simd_float4x4 = .init()
    var projection: simd_float4x4 = .init()
    var cameraPosition: simd_float3 = .init()

    func makeBuffer() -> MTLBuffer {
        var data = self
        let device = Shared.properties.device!
        return device.makeBuffer(bytes: &data, length: MemoryLayout<Self>.stride, options: [])!
    }

    func modifyBuffer(_ buffer: inout MTLBuffer) {
        var newData = self
        let pointer = buffer.contents()
        memcpy(pointer, &newData, MemoryLayout<Self>.stride)
    }
}

/// Arguments to pass to the viewport grid shader
struct GridUniforms {
    var invViewProjection: simd_float4x4
    var gridSpacing: Float
    var cameraPos: simd_float3
    var fadeStart: Float
    var fadeEnd: Float

    init() {
        self.invViewProjection = matrix_identity_float4x4
        self.gridSpacing = 1.0
        self.cameraPos = simd_float3(0, 0, 0)
        self.fadeStart = 10.0
        self.fadeEnd = 100.0
    }
}
