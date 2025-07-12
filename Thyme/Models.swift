import Foundation
import ModelIO
import SceneKit
import Tide

extension CoreObject {
    /// Load a 3D model using Model I/O (Apple's official framework)
    /// This is much more reliable than manual SceneKit parsing
    public static func loadModel(from url: URL, defaultColor: Tide.Color = .shadeOfWhite(1.0)) throws -> CoreObject {
        var object = try loadModelAndIndices(from: url, defaultColor: defaultColor)
        object.object.indexBufferData = object.indices
        return object.object
    }
    
    /// Load with indices using Model I/O
    public static func loadModelAndIndices(from url: URL, defaultColor: Tide.Color = .shadeOfWhite(1.0)) throws -> (object: CoreObject, indices: [UInt32]?) {
        let asset = MDLAsset(url: url)
        
        guard let firstObject = asset.object(at: 0) as? MDLMesh else {
            throw ModelLoadingError.noGeometryFound
        }
        
        let (vertices, indices) = try extractVerticesAndIndicesFromMDLMesh(firstObject, defaultColor: defaultColor)
        
        guard !vertices.isEmpty else {
            throw ModelLoadingError.noGeometryFound
        }
        
        let object = CoreObject(vertices: vertices)
        if let indices = indices {
            object.submitIndices(indices: indices)
        }
        
        return (object: object, indices: indices)
    }
    
    private static func extractVerticesFromMDLMesh(_ mesh: MDLMesh, defaultColor: Tide.Color) throws -> [CoreVertex] {
        var vertices: [CoreVertex] = []
        
        // Get position attribute
        guard let positionAttribute = mesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributePosition) else {
            throw ModelLoadingError.noGeometryFound
        }
        let positionPointer = positionAttribute.dataStart
        let positionStride = positionAttribute.stride
        let vertexCount = mesh.vertexCount

        for i in 0..<vertexCount {
            let baseAddress = positionPointer.advanced(by: i * positionStride)
            let floatPtr = baseAddress.assumingMemoryBound(to: Float.self)

            let position = Position3d(
                x: floatPtr[0],
                y: floatPtr[1],
                z: floatPtr[2]
            )
            vertices.append(CoreVertex(position: position, color: defaultColor))
        }
        
        return vertices
    }
    
    private static func extractVerticesAndIndicesFromMDLMesh(_ mesh: MDLMesh, defaultColor: Tide.Color) throws -> ([CoreVertex], [UInt32]?) {
        let vertices = try extractVerticesFromMDLMesh(mesh, defaultColor: defaultColor)
        
        // Extract indices
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
