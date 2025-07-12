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

/// The core view where Thyme renders objects
public final class ThymeMetalView: NSObject, MTKViewDelegate {
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState!
    private var device: MTLDevice!
    private var uniformsBuffer: MTLBuffer!

    var objects: [CoreObject] = []

    /// The initializer for the Thyme rendering view
    /// - Parameters:
    ///   - mtkView: The view where the renderer should draw
    ///   - objects: The objects that Thyme has to draw to screen
    public init(mtkView: MTKView, objects: [CoreObject]) {
        super.init()

        device = mtkView.device!
        let frameworkBundle = Bundle(for: ThymeMetalView.self)
        let lib = try! device.makeDefaultLibrary(bundle: frameworkBundle)
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

        vertexDesc.layouts[0].stepFunction = .perVertex
        vertexDesc.layouts[0].stepRate = 1
        vertexDesc.layouts[0].stride = MemoryLayout<MetalVertex>.stride

        pipelineDescriptor.vertexDescriptor = vertexDesc

        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
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
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    /// The main drawing loop for the MTLView
    /// - Parameter view: The view where the renderer should render its contents
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
        renderEncoder.setRenderPipelineState(pipelineState)
        var uniforms = Uniforms()
        uniformsBuffer = uniforms.makeBuffer()

        for object in objects {
            renderEncoder.setVertexBuffer(object.buffer, offset: 0, index: 0)
            uniforms.model = object.model
            uniforms.modifyBuffer(&uniformsBuffer)
            renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)

            if object.indexBuffer == nil {
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: object.vertices.count)
            } else {
                renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: object.indexBufferData!.count, indexType: .uint32, indexBuffer: object.indexBuffer!, indexBufferOffset: 0)
            }
        }

        // End rendering
        renderEncoder.endEncoding()
        commandBuffer!.present(drawable)
        commandBuffer!.commit()
    }
}

/// The representation of a ThymeMetalView for SwiftUI
public struct ThymeView: NSViewRepresentable {
    @ObservedObject public var scene: ThymeScene

    public init(scene: ThymeScene) {
        self.scene = scene
    }

    public func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 60

        context.coordinator.renderer = ThymeMetalView(mtkView: mtkView, objects: scene.objects)
        mtkView.delegate = context.coordinator.renderer
        return mtkView
    }

    public func updateNSView(_ nsView: MTKView, context: Context) {
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

    public init(objects: [CoreObject] = []) {
        self.objects = objects
    }
}
