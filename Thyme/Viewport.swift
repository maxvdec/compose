//
//  Viewport.swift
//  Compose
//
//  Created by Max Van den Eynde on 13/7/25.
//

import AppKit
import Metal
import MetalKit
import SwiftUI
import Tide

public class ThymeViewport: NSView {
    private var mtkView: MTKView
    private var camera: Camera
    private var lastMouseLocation: NSPoint?
    private var isRightMouseDown = false
    private var isLeftMouseDown = false
    private var isOtherMouseDown = false
    
    override public var acceptsFirstResponder: Bool {
        return true
    }
    
    init(camera: Camera) {
        self.camera = camera
        self.mtkView = MTKView()
        super.init(frame: .zero)
        
        setupMTKView()
        addSubview(mtkView)
        
        self.wantsLayer = true
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Cannot initialize this view from a coder.")
    }
    
    private func setupMTKView() {
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override public func layout() {
        super.layout()
        mtkView.frame = bounds
    }
    
    override public func mouseDown(with event: NSEvent) {
        isLeftMouseDown = true
        lastMouseLocation = event.locationInWindow
        super.mouseDown(with: event)
    }
        
    override public func mouseDragged(with event: NSEvent) {
        guard let lastLocation = lastMouseLocation else { return }
            
        let currentLocation = event.locationInWindow
        let deltaX = Float(currentLocation.x - lastLocation.x)
        let deltaY = Float(currentLocation.y - lastLocation.y)
            
        if isLeftMouseDown {}
            
        lastMouseLocation = currentLocation
        super.mouseDragged(with: event)
    }
        
    override public func mouseUp(with event: NSEvent) {
        isLeftMouseDown = false
        lastMouseLocation = nil
        super.mouseUp(with: event)
    }
        
    override public func rightMouseDown(with event: NSEvent) {
        isRightMouseDown = true
        lastMouseLocation = event.locationInWindow
        super.rightMouseDown(with: event)
    }
        
    override public func rightMouseDragged(with event: NSEvent) {
        guard let lastLocation = lastMouseLocation else { return }
            
        let currentLocation = event.locationInWindow
        let deltaX = Float(currentLocation.x - lastLocation.x)
        let deltaY = Float(currentLocation.y - lastLocation.y)
            
        if isRightMouseDown {
            let sensitivity: Float = 0.01
            camera.orbit(deltaAzimuth: -deltaX * sensitivity, deltaElevation: deltaY * sensitivity)
        }
            
        lastMouseLocation = currentLocation
        super.rightMouseDragged(with: event)
    }
        
    override public func rightMouseUp(with event: NSEvent) {
        isRightMouseDown = false
        lastMouseLocation = nil
        super.rightMouseUp(with: event)
    }
        
    override public func otherMouseDown(with event: NSEvent) {
        if event.buttonNumber == 2 { // Middle mouse button
            isOtherMouseDown = true
            lastMouseLocation = event.locationInWindow
        }
        super.otherMouseDown(with: event)
    }
        
    override public func otherMouseDragged(with event: NSEvent) {
        guard let lastLocation = lastMouseLocation else { return }
            
        let currentLocation = event.locationInWindow
        let deltaX = Float(currentLocation.x - lastLocation.x)
        let deltaY = Float(currentLocation.y - lastLocation.y)
            
        if isOtherMouseDown && event.buttonNumber == 2 {
            if event.modifierFlags.contains(.shift) {
            } else {
                let sensitivity: Float = 0.01
                camera.pan(deltaX: -deltaX * sensitivity, deltaY: -deltaY * sensitivity)
            }
        }
            
        lastMouseLocation = currentLocation
        super.otherMouseDragged(with: event)
    }
        
    override public func otherMouseUp(with event: NSEvent) {
        if event.buttonNumber == 2 {
            isOtherMouseDown = false
            lastMouseLocation = nil
        }
        super.otherMouseUp(with: event)
    }
        
    override public func scrollWheel(with event: NSEvent) {
        if event.hasPreciseScrollingDeltas {
            let deltaX = Float(event.scrollingDeltaX)
            let deltaY = Float(event.scrollingDeltaY)
            
            if event.modifierFlags.contains(.option) {
                let zoomDelta = Float(event.scrollingDeltaY)
                camera.zoom(delta: zoomDelta * 0.1)
            } else if event.modifierFlags.contains(.shift) {
                let sensitivity: Float = 0.005
                camera.pan(deltaX: -deltaX * sensitivity, deltaY: deltaY * sensitivity)
            } else {
                let sensitivity: Float = 0.005
                camera.orbit(deltaAzimuth: -deltaX * sensitivity, deltaElevation: deltaY * sensitivity)
            }
            
        } else {
            let zoomDelta = Float(event.scrollingDeltaY)
            camera.zoom(delta: zoomDelta * 0.4)
        }
        super.scrollWheel(with: event)
    }
    
    override public func smartMagnify(with event: NSEvent) {}
    
    override public func magnify(with event: NSEvent) {
        let zoomDelta = Float(event.magnification)
        camera.zoom(delta: -zoomDelta * 2.0)
        super.magnify(with: event)
    }
        
    func getMTKView() -> MTKView {
        return mtkView
    }
}
