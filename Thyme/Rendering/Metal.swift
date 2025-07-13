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
}

/// Arguments to pass to the metal shader
struct Uniforms {
    var model: simd_float4x4 = .init()
    var view: simd_float4x4 = .init()
    var projection: simd_float4x4 = .init()

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
