import Foundation
import ModelIO
import SceneKit
import Tide

public extension CoreObject {
    /// Load a 3D model using Model I/O with comprehensive error handling
    static func loadModel(from url: URL, defaultColor: Tide.Color = .shadeOfWhite(1.0)) throws -> CoreObject {
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
        
        let (vertices, indices) = try extractVerticesAndIndicesFromMDLMesh(firstObject, defaultColor: defaultColor)
        
        guard !vertices.isEmpty else {
            throw ModelLoadingError.noGeometryFound
        }
    
        let object = CoreObject(vertices: vertices)
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
                print("⚠️ Unsupported index type: \(indexType)")
                indices = nil
            }
        } else {}
        
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
