//
//  CoreObject.swift
//  Compose
//
//  Created by Max Van den Eynde on 12/7/25.
//

import Combine
import simd
import SwiftUI
import Tide

/// Structure that defines core vertices that create shapes
public struct CoreVertex {
    /// The position of the target vertex in the space
    public var position: Position3d
    /// The color of the target vertex
    public var color: Tide.Color

    public init(position: Position3d, color: Tide.Color) {
        self.position = position
        self.color = color
    }

    /// Helper function that transforms a CoreVertex to a Metal Vertex
    /// - Returns: A MetalVertex result of the transformation
    func toMetal() -> MetalVertex {
        return MetalVertex(position: position.toSimd(), color: color.toSimd())
    }
}

/// Class that defines the highest abstraction of a representable object
public final class CoreObject: Identifiable, ObservableObject {
    /// The vertices that conform the object
    @Published var vertices: [CoreVertex] {
        didSet {
            makeBuffers()
        }
    }

    /// Indices that indicate the order the vertices are drawn
    @Published var indexBufferData: [UInt32]? {
        didSet {
            makeBuffers()
        }
    }

    /// Offset of the vertices of the object
    @Published public var position: Position3d = [0, 0, 0] {
        didSet {
            makeModel()
        }
    }

    /// Scale of the object
    @Published public var scale: Size3d = [1, 1, 1] {
        didSet {
            makeModel()
        }
    }

    /// Rotation of the target object
    @Published public var rotation: Rotation3d = [0, 0, 0] {
        didSet {
            makeModel()
        }
    }

    /// The buffer that contains the main vertex data
    var buffer: MTLBuffer!

    /// The buffer that contains the indices for indexed drawing
    var indexBuffer: MTLBuffer?

    /// Matrix that defines transformations of the object
    var model: float4x4 = .init()

    public init(vertices: [CoreVertex]) {
        self.vertices = vertices
        makeBuffers()
        makeModel()
    }

    public func submitIndices(indices: [UInt32]) {
        indexBufferData = indices
    }

    /// Function that makes the vertex buffer based on the vertices that the Object has
    func makeBuffers() {
        var metalVertices = vertices.map {
            $0.toMetal()
        }
        buffer = Shared.properties.device.makeBuffer(bytes: &metalVertices, length: MemoryLayout<MetalVertex>.stride * metalVertices.count, options: [])
        if var indices = indexBufferData {
            indexBuffer = Shared.properties.device.makeBuffer(bytes: &indices, length: MemoryLayout<UInt32>.stride * indices.count)
        }
    }

    /// Construct the model matrix that defines traits of the object itself
    func makeModel() {
        let scaleMatrix = simd_float4x4(
            SIMD4(scale.x, 0, 0, 0),
            SIMD4(0, scale.y, 0, 0),
            SIMD4(0, 0, scale.z, 0),
            SIMD4(0, 0, 0, 1)
        )

        let rotationX = simd_float4x4(
            SIMD4(1, 0, 0, 0),
            SIMD4(0, cos(rotation.x), sin(rotation.x), 0),
            SIMD4(0, -sin(rotation.x), cos(rotation.x), 0),
            SIMD4(0, 0, 0, 1)
        )

        let rotationY = simd_float4x4(
            SIMD4(cos(rotation.y), 0, -sin(rotation.y), 0),
            SIMD4(0, 1, 0, 0),
            SIMD4(sin(rotation.y), 0, cos(rotation.y), 0),
            SIMD4(0, 0, 0, 1)
        )

        let rotationZ = simd_float4x4(
            SIMD4(cos(rotation.z), sin(rotation.z), 0, 0),
            SIMD4(-sin(rotation.z), cos(rotation.z), 0, 0),
            SIMD4(0, 0, 1, 0),
            SIMD4(0, 0, 0, 1)
        )

        let rotationMatrix = rotationZ * rotationY * rotationX

        let translationMatrix = simd_float4x4(
            SIMD4(1, 0, 0, 0),
            SIMD4(0, 1, 0, 0),
            SIMD4(0, 0, 1, 0),
            SIMD4(position.x, position.y, position.z, 1)
        )

        model = translationMatrix * rotationMatrix * scaleMatrix
    }
}
