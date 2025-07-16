//
//  Primitive.swift
//  Compose
//
//  Created by Max Van den Eynde on 16/7/25.
//

import Metal
import MetalKit
import ModelIO
import Tide

extension CoreObject {
    public static func box(_ extent: Position3d = [1, 1, 1], _ segments: Vector3d = [1, 1, 1]) -> CoreObject {
        let allocator = MTKMeshBufferAllocator(device: Shared.properties.device)
        let segments = SIMD3<UInt32>(UInt32(segments.x), UInt32(segments.y), UInt32(segments.z))
        let cubeMesh = MDLMesh(boxWithExtent: extent.toSimd(), segments: segments, inwardNormals: false, geometryType: .triangles, allocator: allocator)
        return try! CoreObject.importMDLMesh(cubeMesh)
    }
}
