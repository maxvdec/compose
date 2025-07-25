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
    /// Property that indicates the shader which way is up
    public var normal: Vector3d = [0, 0, 0]

    public init(position: Position3d, color: Tide.Color, normal: Vector3d = [0, 0, 0]) {
        self.position = position
        self.color = color
        self.normal = normal
    }

    /// Helper function that transforms a CoreVertex to a Metal Vertex
    /// - Returns: A MetalVertex result of the transformation
    func toMetal() -> MetalVertex {
        return MetalVertex(position: position.toSimd(), color: color.toSimd(), normals: normal.toSimd())
    }
}

/// Class that defines the highest abstraction of a representable object
public final class CoreObject: Identifiable, ObservableObject, Equatable {
    public static func == (lhs: CoreObject, rhs: CoreObject) -> Bool {
        return lhs.id == rhs.id
    }

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

    private var lastSmooth: Bool = true

    @Published public var shadeSmooth: Bool = true {
        didSet {
            if shadeSmooth != lastSmooth {
                if !shadeSmooth {
                    convertToSmoothShading()
                } else {
                    convertToFlatShading()
                }
                makeBuffers()
                lastSmooth = shadeSmooth
            } else {
                lastSmooth = !shadeSmooth
            }
        }
    }

    /// The buffer that contains the main vertex data
    var buffer: MTLBuffer!

    /// The buffer that contains the indices for indexed drawing
    var indexBuffer: MTLBuffer?

    /// Matrix that defines transformations of the object
    var model: float4x4 = .init()

    /// The ID of the object
    public let id: UUID = .init()

    public init(vertices: [CoreVertex]) {
        self.vertices = vertices
        makeBuffers()
        makeModel()
    }

    /// Function that submits the indices for index drawing
    /// - Parameter indices: The array of indices that Thyme should follow for rendering
    public func submitIndices(indices: [UInt32]) {
        indexBufferData = indices
    }

    /// Function that submits normals to the target vertices
    /// - Parameter normals: The normals submitted to the vertices
    public func submitNormals(normals: [Vector3d]) {
        for i in vertices.indices {
            vertices[i].normal = normals[i]
        }
    }

    /// Function that makes the vertex buffer based on the vertices that the Object has
    func makeBuffers() {
        var metalVertices = vertices.map {
            $0.toMetal()
        }
        if vertices.count == 0 {
            return
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

public extension CoreObject {
    /// Uses flat shading for the object, meaning that the normals are not going to be interpolated
    func convertToFlatShading() {
        guard let indices = indexBufferData else {
            fatalError("Needed indices for flat shading")
        }

        var newVertices: [CoreVertex] = []
        var newIndices: [UInt32] = []

        for i in stride(from: 0, to: indices.count, by: 3) {
            guard i + 2 < indices.count else { break }

            let i0 = Int(indices[i])
            let i1 = Int(indices[i + 1])
            let i2 = Int(indices[i + 2])

            guard i0 < vertices.count, i1 < vertices.count, i2 < vertices.count else { continue }

            let v0 = vertices[i0]
            let v1 = vertices[i1]
            let v2 = vertices[i2]

            let edge1 = Vector3d(v1.position.x - v0.position.x, v1.position.y - v0.position.y, v1.position.z - v0.position.z)
            let edge2 = Vector3d(v2.position.x - v0.position.x, v2.position.y - v0.position.y, v2.position.z - v0.position.z)
            let faceNormal = cross(edge1, edge2).normalized()

            var newV0 = v0
            var newV1 = v1
            var newV2 = v2

            newV0.normal = faceNormal
            newV1.normal = faceNormal
            newV2.normal = faceNormal

            // Add vertices to new array
            newVertices.append(newV0)
            newVertices.append(newV1)
            newVertices.append(newV2)

            // Create new indices that reference the new vertices
            let baseIndex = UInt32(newVertices.count - 3)
            newIndices.append(baseIndex)
            newIndices.append(baseIndex + 1)
            newIndices.append(baseIndex + 2)
        }

        vertices = newVertices
        indexBufferData = newIndices
    }

    /// Converts flat shaded geometry back to smooth shading by merging duplicate vertices
    /// and averaging their normals
    func convertToSmoothShading(tolerance: Float = 0.0001) {
        guard !vertices.isEmpty else { return }
        guard vertices.count % 3 == 0 else {
            fatalError("Vertex count must be multiple of 3 for triangulated mesh. Vertices were \(vertices.count)")
        }

        var uniqueVertices: [CoreVertex] = []
        var newIndices: [UInt32] = []
        var vertexMap: [String: Int] = [:]
        var normalAccumulator: [Vector3d] = []
        var normalCounts: [Int] = []

        func positionKey(for vertex: CoreVertex) -> String {
            let x = String(format: "%.6f", vertex.position.x)
            let y = String(format: "%.6f", vertex.position.y)
            let z = String(format: "%.6f", vertex.position.z)
            return "\(x),\(y),\(z)"
        }

        for i in stride(from: 0, to: vertices.count, by: 3) {
            let v0 = vertices[i]
            let v1 = vertices[i + 1]
            let v2 = vertices[i + 2]

            let edge1 = Vector3d(v1.position.x - v0.position.x,
                                 v1.position.y - v0.position.y,
                                 v1.position.z - v0.position.z)
            let edge2 = Vector3d(v2.position.x - v0.position.x,
                                 v2.position.y - v0.position.y,
                                 v2.position.z - v0.position.z)
            let faceNormal = cross(edge1, edge2)
            let faceArea = faceNormal.magnitude() * 0.5
            let normalizedFaceNormal = faceNormal.normalized()

            for vertex in [v0, v1, v2] {
                let key = positionKey(for: vertex)

                if let existingIndex = vertexMap[key] {
                    normalAccumulator[existingIndex] = normalAccumulator[existingIndex] +
                        (normalizedFaceNormal * faceArea)
                    normalCounts[existingIndex] += 1
                } else {
                    let newIndex = uniqueVertices.count
                    vertexMap[key] = newIndex

                    var newVertex = vertex
                    uniqueVertices.append(newVertex)
                    normalAccumulator.append(normalizedFaceNormal * faceArea)
                    normalCounts.append(1)
                }
            }
        }

        for i in 0 ..< uniqueVertices.count {
            uniqueVertices[i].normal = normalAccumulator[i].normalized()
        }

        for vertex in vertices {
            let key = positionKey(for: vertex)
            if let index = vertexMap[key] {
                newIndices.append(UInt32(index))
            }
        }

        vertices = uniqueVertices
        indexBufferData = newIndices
    }
}
