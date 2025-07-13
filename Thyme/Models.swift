import Foundation
import ModelIO
import SceneKit
import Tide

public extension CoreObject {
    /// Load a 3D model using Model I/O with comprehensive error handling and normal generation
    static func loadModel(from url: URL, defaultColor: Tide.Color = .shadeOfWhite(1)) throws -> CoreObject {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ModelLoadingError.fileNotFound
        }
        
        let asset = MDLAsset(url: url)
        
        guard asset.count > 0 else {
            throw ModelLoadingError.noGeometryFound
        }
        
        guard let firstObject = asset.object(at: 0) as? MDLMesh else {
            throw ModelLoadingError.noGeometryFound
        }
        
        if firstObject.vertexAttributeData(forAttributeNamed: MDLVertexAttributeNormal) == nil {
            firstObject.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 0.5)
        }
        
        let (vertices, indices) = try extractVerticesAndIndicesFromMDLMesh(firstObject, defaultColor: defaultColor)
        
        guard !vertices.isEmpty else {
            throw ModelLoadingError.noGeometryFound
        }
        
        var finalVertices = vertices
        if finalVertices.allSatisfy({ $0.normal == Vector3d(0, 0, 0) }) {
            finalVertices = generateNormalsForGeometry(vertices: finalVertices, indices: indices)
        }
    
        let object = CoreObject(vertices: finalVertices)
        if let indices = indices {
            object.submitIndices(indices: indices)
        }
                
        return object
    }
    
    /// Load with indices using Model I/O
    static func loadModelAndIndices(from url: URL, defaultColor: Tide.Color = .shadeOfWhite(1.0)) throws -> (object: CoreObject, indices: [UInt32]?) {
        let object = try loadModel(from: url, defaultColor: defaultColor)
        return (object: object, indices: object.indexBufferData)
    }
    
    private static func extractVerticesAndIndicesFromMDLMesh(_ mesh: MDLMesh, defaultColor: Tide.Color) throws -> ([CoreVertex], [UInt32]?) {
        var vertices: [CoreVertex] = []
        
        guard let positionAttribute = mesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributePosition) else {
            throw ModelLoadingError.noGeometryFound
        }
        
        let positionPointer = positionAttribute.dataStart
        let positionStride = positionAttribute.stride
        let vertexCount = mesh.vertexCount
        
        let normalAttribute = mesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeNormal)
        let normalPointer = normalAttribute?.dataStart
        let normalStride = normalAttribute?.stride ?? 0
        
        for i in 0..<vertexCount {
            let positionBaseAddress = positionPointer.advanced(by: i * positionStride)
            let positionFloatPtr = positionBaseAddress.assumingMemoryBound(to: Float.self)
                    
            let position = Position3d(
                x: positionFloatPtr[0],
                y: positionFloatPtr[1],
                z: positionFloatPtr[2]
            )
                    
            var normal = Vector3d(0, 0, 0)
            if let normalPointer = normalPointer {
                let normalBaseAddress = normalPointer.advanced(by: i * normalStride)
                let normalFloatPtr = normalBaseAddress.assumingMemoryBound(to: Float.self)
                        
                normal = Vector3d(
                    normalFloatPtr[0],
                    normalFloatPtr[1],
                    normalFloatPtr[2]
                )
            }
                    
            vertices.append(CoreVertex(position: position, color: defaultColor, normal: normal))
        }
        
        var indices: [UInt32]?
        if let submesh = mesh.submeshes?.firstObject as? MDLSubmesh {
            let indexBuffer = submesh.indexBuffer
            let indexCount = submesh.indexCount
            let indexType = submesh.indexType
            
            let bufferData = indexBuffer.map().bytes
            
            indices = []
            switch indexType {
            case .uInt16:
                let shortPtr = bufferData.bindMemory(to: UInt16.self, capacity: indexCount)
                for i in 0..<indexCount {
                    indices?.append(UInt32(shortPtr[i]))
                }
            case .uInt32:
                let intPtr = bufferData.bindMemory(to: UInt32.self, capacity: indexCount)
                for i in 0..<indexCount {
                    indices?.append(intPtr[i])
                }
            default:
                
                indices = nil
            }
        }
        
        return (vertices, indices)
    }
    
    /// Generate normals for geometry (indexed or non-indexed)
    private static func generateNormalsForGeometry(vertices: [CoreVertex], indices: [UInt32]?) -> [CoreVertex] {
        if let indices = indices {
            return generateNormalsForIndexedGeometry(vertices: vertices, indices: indices)
        } else {
            return generateNormalsForTriangles(vertices: vertices)
        }
    }
    
    /// Generate normals for indexed geometry
    private static func generateNormalsForIndexedGeometry(vertices: [CoreVertex], indices: [UInt32]) -> [CoreVertex] {
        var newVertices = vertices
        
        for i in 0..<newVertices.count {
            newVertices[i].normal = Vector3d(0, 0, 0)
        }
        
        for i in stride(from: 0, to: indices.count, by: 3) {
            guard i + 2 < indices.count else { break }
            
            let i0 = Int(indices[i])
            let i1 = Int(indices[i + 1])
            let i2 = Int(indices[i + 2])
            
            guard i0 < vertices.count, i1 < vertices.count, i2 < vertices.count else { continue }
            
            let v0 = vertices[i0].position
            let v1 = vertices[i1].position
            let v2 = vertices[i2].position
            
            let edge1 = Vector3d(v1.x - v0.x, v1.y - v0.y, v1.z - v0.z)
            let edge2 = Vector3d(v2.x - v0.x, v2.y - v0.y, v2.z - v0.z)
            
            let normal = cross(edge1, edge2).normalized()
            
            newVertices[i0].normal += normal
            newVertices[i1].normal += normal
            newVertices[i2].normal += normal
        }
        
        for i in 0..<newVertices.count {
            newVertices[i].normal = newVertices[i].normal.normalized()
        }
        
        return newVertices
    }
    
    /// Generate normals for non-indexed triangle geometry
    private static func generateNormalsForTriangles(vertices: [CoreVertex]) -> [CoreVertex] {
        var newVertices = vertices
        
        for i in stride(from: 0, to: vertices.count, by: 3) {
            guard i + 2 < vertices.count else { break }
            
            let v0 = vertices[i].position
            let v1 = vertices[i + 1].position
            let v2 = vertices[i + 2].position
            
            let edge1 = Vector3d(v1.x - v0.x, v1.y - v0.y, v1.z - v0.z)
            let edge2 = Vector3d(v2.x - v0.x, v2.y - v0.y, v2.z - v0.z)
            
            let normal = cross(edge1, edge2).normalized()
            
            newVertices[i].normal = normal
            newVertices[i + 1].normal = normal
            newVertices[i + 2].normal = normal
        }
        
        return newVertices
    }
}

/// Helper extensions for Vector3d math operations
extension Vector3d {
    /// Calculate the cross product of two vectors
    static func cross(_ a: Vector3d, _ b: Vector3d) -> Vector3d {
        return Vector3d(
            a.y * b.z - a.z * b.y,
            a.z * b.x - a.x * b.z,
            a.x * b.y - a.y * b.x
        )
    }
    
    /// Calculate the magnitude of the vector
    var magnitude: Float {
        return sqrt(x * x + y * y + z * z)
    }
    
    /// Return a normalized version of the vector
    func normalized() -> Vector3d {
        let mag = magnitude
        guard mag > 0 else { return Vector3d(0, 1, 0) } // Default up vector if zero
        return Vector3d(x / mag, y / mag, z / mag)
    }
    
    /// Add two vectors
    static func + (lhs: Vector3d, rhs: Vector3d) -> Vector3d {
        return Vector3d(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }
    
    /// Add-assign operator
    static func += (lhs: inout Vector3d, rhs: Vector3d) {
        lhs = lhs + rhs
    }
    
    /// Check if two vectors are equal
    static func == (lhs: Vector3d, rhs: Vector3d) -> Bool {
        return abs(lhs.x - rhs.x) < 0.0001 &&
            abs(lhs.y - rhs.y) < 0.0001 &&
            abs(lhs.z - rhs.z) < 0.0001
    }
}

/// Helper function for cross product (global scope)
func cross(_ a: Vector3d, _ b: Vector3d) -> Vector3d {
    return Vector3d.cross(a, b)
}

public enum ModelLoadingError: Error {
    case fileNotFound
    case unsupportedFormat
    case noGeometryFound
    case corruptedData
    
    public var localizedDescription: String {
        switch self {
        case .fileNotFound:
            return "Model file not found or could not be loaded"
        case .unsupportedFormat:
            return "Unsupported model format"
        case .noGeometryFound:
            return "No geometry found in model"
        case .corruptedData:
            return "Model data is corrupted"
        }
    }
}
