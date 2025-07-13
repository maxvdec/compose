//
//  Camera.swift
//  Compose
//
//  Created by Max Van den Eynde on 13/7/25.
//

import Combine
import Metal
import MetalKit
import SwiftUI
import Tide

public extension Float {
    static func toRadians(_ angle: Float) -> Float {
        return angle * .pi / 180
    }
}

public class Camera {
    /// Point that indicates the position in the space of the camera
    @Published var position: Position3d {
        didSet {
            distance = length(target.toSimd() - position.toSimd())
            updateOrbitalParameters()
            viewMatrix()
        }
    }

    /// Point that indicates how the camera should be oriented to see that point
    @Published var target: Position3d {
        didSet {
            distance = length(target.toSimd() - position.toSimd())
            updateOrbitalParameters()
            viewMatrix()
        }
    }

    /// Axis where the camera is positioned and rotates along it
    @Published public var up: Vector3d {
        didSet {
            viewMatrix()
        }
    }

    /// The field of view of the camera
    @Published public var fov: Float = .toRadians(45.0) {
        didSet {
            projectionMatrix()
        }
    }

    /// The aspect ratio. Calculated with `width / height`
    @Published public var aspectRatio: Float {
        didSet {
            projectionMatrix()
        }
    }

    /// The distance where the nearest objects to the camera can be seen
    @Published public var nearPlane: Float = 0.1 {
        didSet {
            projectionMatrix()
        }
    }

    /// The distance where the farthest objects to the camera can be seen
    @Published public var farPlane: Float = 1000 {
        didSet {
            projectionMatrix()
        }
    }

    /// Matrix that defines how objects should be placed relative to the camera
    var view: float4x4 = .init()
    /// Matrix that defines how the viewport should be structured
    var projection: float4x4 = .init()

    /// Variable that represents the distance of the orbit from the target
    private var distance: Float = 5.0
    /// Horizontal rotation over the target
    private var azimuth: Float = 0.0
    /// Vertical rotation over the target
    private var elevation: Float = 0.0
    /// The center of the orbit
    private var orbitCenter: Position3d = [0, 0, 0]

    public init(position: Position3d = [0, 0, 0], target: Position3d = [0, 0, -1], up: Position3d = [0, 1, 0], aspectRatio: Float = 1.0) {
        self.position = position
        self.up = up
        self.target = target
        self.aspectRatio = aspectRatio
        self.orbitCenter = target

        let toTarget = target.toSimd() - position.toSimd()
        self.distance = length(toTarget)
        self.azimuth = atan2(toTarget.x, toTarget.z)
        self.elevation = asin(toTarget.y / distance)

        viewMatrix()
        projectionMatrix()
    }

    /// Function that generates and stores the view matrix
    public func viewMatrix() {
        let zAxis = normalize(position.toSimd() - target.toSimd())
        let xAxis = normalize(cross(up.toSimd(), zAxis))
        let yAxis = cross(zAxis, xAxis)

        view = float4x4(
            SIMD4(xAxis.x, yAxis.x, zAxis.x, 0),
            SIMD4(xAxis.y, yAxis.y, zAxis.y, 0),
            SIMD4(xAxis.z, yAxis.z, zAxis.z, 0),
            SIMD4(-dot(xAxis, position.toSimd()), -dot(yAxis, position.toSimd()), -dot(zAxis, position.toSimd()), 1),
        )
    }

    /// Move the camera to a determinate position
    /// - Parameter position: The new position for the camera
    public func move(to position: Position3d) {
        self.position = position
    }

    /// Change the point that the camera treats as center
    /// - Parameter point: The new center of the camera
    public func look(at point: Position3d) {
        target = point
    }

    /// Function that generates and stores the projection matrix
    public func projectionMatrix() {
        let tanHalfFov = tan(fov / 2)

        projection = float4x4(
            SIMD4(1.0 / (aspectRatio * tanHalfFov), 0, 0, 0),
            SIMD4(0, 1.0 / tanHalfFov, 0, 0),
            SIMD4(0, 0, -(farPlane + nearPlane) / (farPlane - nearPlane), -1),
            SIMD4(0, 0, -(2.0 * farPlane * nearPlane) / (farPlane - nearPlane), 0)
        )
    }

    /// Function that updates the aspect ratio based on the dimensions of the viewport
    /// - Parameters:
    ///   - width: The length of the main X axis of the new viewport
    ///   - height: The length of the main Y axis of the new viewport
    public func updateAspectRatio(width: Float, height: Float) {
        aspectRatio = width / height
    }

    /// Function that restructures camera properties from a new orbit defined
    /// - Parameters:
    ///   - deltaAzimuth: The value added to the current horizontal pan
    ///   - deltaElevation: The value added to the current vertical pan
    public func orbit(deltaAzimuth: Float, deltaElevation: Float) {
        azimuth += deltaAzimuth
        elevation += deltaElevation

        elevation = max(-Float.pi / 2 + 0.1, min(Float.pi / 2 - 0.1, elevation))

        updatePositionFromOrbit()
    }

    /// Pans the view though some movement
    /// - Parameters:
    ///   - deltaX: The X scalar of the movement
    ///   - deltaY: The Y scalar of the movement
    public func pan(deltaX: Float, deltaY: Float, deltaZ: Float) {
        let right = normalize(cross(up.toSimd(), position.toSimd() - target.toSimd()))
        let upVector = normalize(cross(position.toSimd() - target.toSimd(), right))
        let forward = normalize(target.toSimd() - position.toSimd())

        let panOffset = right * deltaX + upVector * deltaY + forward * deltaZ

        let newTarget = target.toSimd() + panOffset
        let newPosition = position.toSimd() + panOffset

        target = Position3d(newTarget.x, newTarget.y, newTarget.z)
        position = Position3d(newPosition.x, newPosition.y, newPosition.z)
        orbitCenter = target
    }

    /// Zooms into the view with a minimum of `0.1` and maximum of `100.0`
    /// - Parameter delta: The new scalar added to the current zoom
    public func zoom(delta: Float) {
        distance *= (1.0 + delta * 0.1)
        distance = max(0.1, min(100.0, distance))
        updatePositionFromOrbit()
    }

    private func updatePositionFromOrbit() {
        let x = distance * cos(elevation) * sin(azimuth)
        let y = distance * sin(elevation)
        let z = distance * cos(elevation) * cos(azimuth)

        position = Position3d(orbitCenter.x + x, orbitCenter.y + y, orbitCenter.z + z)
    }

    private func updateOrbitalParameters() {
        orbitCenter = target
        let fromTarget = position.toSimd() - target.toSimd()

        if distance > 0 {
            azimuth = atan2(fromTarget.x, fromTarget.z)
            elevation = asin(fromTarget.y / distance)
        }
    }
}

