//
//  CoreView.swift
//  Compose
//
//  Created by Max Van den Eynde on 12/7/25.
//

import Combine
import Foundation
import Metal
import MetalKit
import SwiftUI
import Tide

/// The core view where Thyme renders objects
public final class ThymeMetalView: NSObject, MTKViewDelegate {
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState!
    private var device: MTLDevice!
    private var uniformsBuffer: MTLBuffer!
    private var depthStencilState: MTLDepthStencilState!

    private var gridPipelineState: MTLRenderPipelineState!
    private var gridUniformsBuffer: MTLBuffer!
    private var gridDepthStencilState: MTLDepthStencilState!

    var objects: [CoreObject]
    var camera: Camera

    /// The initializer for the Thyme rendering view
    /// - Parameters:
    ///   - mtkView: The view where the renderer should draw
    ///   - objects: The objects that Thyme has to draw to screen
    public init(mtkView: MTKView, objects: [CoreObject], camera: Camera) {
        self.camera = camera
        self.objects = objects
        super.init()

        device = mtkView.device!
        let frameworkBundle = Bundle(for: ThymeMetalView.self)
        let lib = try! device.makeDefaultLibrary(bundle: frameworkBundle)

        // Setup main rendering pipeline
        setupMainPipeline(lib: lib)

        // Setup grid rendering pipeline
        setupGridPipeline(lib: lib)

        // Setup depth stencil states
        setupDepthStencilStates()
    }

    private func setupMainPipeline(lib: MTLLibrary) {
        let vertexFunc = lib.makeFunction(name: "vertex_main")!
        let fragFunc = lib.makeFunction(name: "fragment_main")!

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        let vertexDesc = MTLVertexDescriptor()
        var offset = 0

        // Position attribute
        vertexDesc.attributes[0].format = .float3
        vertexDesc.attributes[0].offset = 0
        vertexDesc.attributes[0].bufferIndex = 0

        offset += MemoryLayout<simd_float3>.stride

        // Color attribute
        vertexDesc.attributes[1].format = .float4
        vertexDesc.attributes[1].offset = offset
        vertexDesc.attributes[1].bufferIndex = 0

        offset += MemoryLayout<simd_float4>.stride

        // Normals attribute
        vertexDesc.attributes[2].format = .float3
        vertexDesc.attributes[2].offset = offset
        vertexDesc.attributes[2].bufferIndex = 0

        vertexDesc.layouts[0].stepFunction = .perVertex
        vertexDesc.layouts[0].stepRate = 1
        vertexDesc.layouts[0].stride = MemoryLayout<MetalVertex>.stride

        pipelineDescriptor.vertexDescriptor = vertexDesc
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    private func setupGridPipeline(lib: MTLLibrary) {
        let gridVertexFunc = lib.makeFunction(name: "grid_vertex")!
        let gridFragFunc = lib.makeFunction(name: "grid_fragment")!

        let gridPipelineDescriptor = MTLRenderPipelineDescriptor()
        gridPipelineDescriptor.vertexFunction = gridVertexFunc
        gridPipelineDescriptor.fragmentFunction = gridFragFunc
        gridPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        gridPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

        // Enable blending for grid transparency
        gridPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        gridPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        gridPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        gridPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        gridPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        gridPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        gridPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        gridPipelineState = try! device.makeRenderPipelineState(descriptor: gridPipelineDescriptor)
    }

    private func setupDepthStencilStates() {
        // Main depth stencil state
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: descriptor)

        // Grid depth stencil state (read depth, don't write)
        let gridDescriptor = MTLDepthStencilDescriptor()
        gridDescriptor.depthCompareFunction = .less
        gridDescriptor.isDepthWriteEnabled = false // Don't write to depth buffer
        gridDepthStencilState = device.makeDepthStencilState(descriptor: gridDescriptor)
    }

    /// Unused initialitzation from coder
    /// - Parameter coder: A coder from which you may initialize a view
    /// - Warning: This method should not be used
    @available(*, unavailable)
    public required init(coder: NSCoder) {
        fatalError("Cannot use this method of initialization")
    }

    /// Updates the parameters when the view's domains are changed
    /// - Parameters:
    ///   - view: The view that has changed
    ///   - size: The target domains the view is reaching
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        camera.aspectRatio = Float(size.width / size.height)
    }

    /// The main drawing loop for the MTLView
    /// - Parameter view: The view where the renderer should render its contents
    ///
    /// It executes mainly two renders (render passes):
    /// - **The Grid Pass** serves as the grid and viewport of the editor
    /// - **The Render Pass** renders the actual objects to the screen
    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor
        else {
            return
        }

        commandQueue = device.makeCommandQueue()

        // Start rendering
        let commandBuffer = commandQueue?.makeCommandBuffer() // For registering commands
        if commandBuffer == nil {
            return
        }

        let renderEncoder = commandBuffer!.makeRenderCommandEncoder(descriptor: descriptor)!

        // PASS 1: Render grid first (background)
        renderGrid(renderEncoder: renderEncoder)

        // PASS 2: Render main objects
        renderObjects(renderEncoder: renderEncoder)

        // End rendering
        renderEncoder.endEncoding()
        commandBuffer!.present(drawable)
        commandBuffer!.commit()
    }

    private func renderGrid(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setRenderPipelineState(gridPipelineState)
        renderEncoder.setDepthStencilState(gridDepthStencilState)

        var gridUniforms = GridUniforms()
        let viewProjection = camera.projection * camera.view
        gridUniforms.invViewProjection = viewProjection.inverse
        gridUniforms.gridSpacing = 0.001
        gridUniforms.cameraPos = camera.position.toSimd()
        gridUniforms.fadeStart = 300.0
        gridUniforms.fadeEnd = 500.0

        if gridUniformsBuffer == nil {
            gridUniformsBuffer = device.makeBuffer(bytes: &gridUniforms,
                                                   length: MemoryLayout<GridUniforms>.stride,
                                                   options: [])
        } else {
            let contents = gridUniformsBuffer.contents().bindMemory(to: GridUniforms.self, capacity: 1)
            contents[0] = gridUniforms
        }

        renderEncoder.setVertexBuffer(gridUniformsBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(gridUniformsBuffer, offset: 0, index: 0)

        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    }

    private func renderObjects(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setDepthStencilState(depthStencilState)

        var uniforms = Uniforms()
        uniformsBuffer = uniforms.makeBuffer()
        uniforms.projection = camera.projection
        uniforms.view = camera.view
        uniforms.cameraPosition = camera.position.toSimd()

        for object in objects {
            renderEncoder.setVertexBuffer(object.buffer, offset: 0, index: 0)
            uniforms.model = object.model
            uniforms.modifyBuffer(&uniformsBuffer)
            renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
            renderEncoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 1)

            if object.indexBuffer == nil {
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: object.vertices.count)
            } else {
                renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: object.indexBufferData!.count, indexType: .uint32, indexBuffer: object.indexBuffer!, indexBufferOffset: 0)
            }
        }
    }
}

/// The representation of a ThymeMetalView for SwiftUI
public struct ThymeView: NSViewRepresentable {
    public typealias NSViewType = ThymeViewport

    @ObservedObject public var scene: ThymeScene

    public init(scene: ThymeScene) {
        self.scene = scene
    }

    public func makeNSView(context: Context) -> ThymeViewport {
        let interactiveView = ThymeViewport(camera: scene.camera)
        let mtkView = interactiveView.getMTKView()

        context.coordinator.renderer = ThymeMetalView(mtkView: mtkView, objects: scene.objects, camera: scene.camera)
        mtkView.delegate = context.coordinator.renderer

        return interactiveView
    }

    public func updateNSView(_ nsView: ThymeViewport, context: Context) {
        context.coordinator.renderer?.objects = scene.objects
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public final class Coordinator {
        var renderer: ThymeMetalView?
    }
}

public final class ThymeScene: ObservableObject {
    @Published public var objects: [CoreObject] = []
    @Published public var camera: Camera = .init()

    public init(objects: [CoreObject] = [], camera: Camera = Camera()) {
        self.objects = objects
        self.camera = camera
    }
}
