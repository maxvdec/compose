//
//  Tide.swift
//  Tide
//
//  Created by Max Van den Eynde on 12/7/25.
//

import Foundation
import simd

/// A struct that represents a point in a tri-dimensional space
public struct Position3d: ExpressibleByArrayLiteral, Equatable {
    /// Position in the X axis for the point
    public var x: Float
    /// Position in the Y axis for the point
    public var y: Float
    /// Position in the Z axis for the point
    public var z: Float

    /// Extent of the object in the X axis
    public var width: Float { x }
    /// Extent of the object in the Y axis
    public var height: Float { y }
    /// Extent of the object in the Z axis
    public var depth: Float { z }

    /// Explicit initializer for the Position3D struct
    /// - Parameters:
    ///   - x: The position in the X axis
    ///   - y: The position in the Y axis
    ///   - z: The position in the Z axis
    public init(x: Float = 0.0, y: Float = 0.0, z: Float = 0.0) {
        self.x = x
        self.y = y
        self.z = z
    }

    /// Explicit initializer for the Position3D struct
    /// - Parameters:
    ///   - x: The position in the X axis
    ///   - y: The position in the Y axis
    ///   - z: The position in the Z axis
    public init(_ x: Float = 0.0, _ y: Float = 0.0, _ z: Float = 0.0) {
        self.x = x
        self.y = y
        self.z = z
    }

    /// Initialization by array
    public init(arrayLiteral elements: Float...) {
        self.x = elements.count > 0 ? elements[0] : 0
        self.y = elements.count > 1 ? elements[1] : 0
        self.z = elements.count > 2 ? elements[2] : 0
    }

    /// Conforms to ExpressibleByArrayLiteral
    public typealias ArrayLiteralElement = Float

    /// A function that transforms a position to get a Metal-compliant type
    /// - Returns: A vector that contains the three values
    public func toSimd() -> simd_float3 {
        return simd_float3(x: x, y: y, z: z)
    }

    /// A function that transforms a position to get a Metal-compliant type
    /// - Returns: A vector that contains the three values, where `w` is `1.0`
    public func toSimd4() -> simd_float4 {
        return simd_float4(x: Float(x), y: Float(y), z: Float(z), w: 1.0)
    }
}

public extension Position3d {
    static func ==(lhs: Position3d, rhs: Position3d) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }

    static func +(lhs: Position3d, rhs: Position3d) -> Position3d {
        return Position3d(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    static func -(lhs: Position3d, rhs: Position3d) -> Position3d {
        return Position3d(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    static func *(lhs: Position3d, rhs: Float) -> Position3d {
        return Position3d(x: lhs.x * rhs, y: lhs.y * rhs, z: lhs.z * rhs)
    }

    static func /(lhs: Position3d, rhs: Float) -> Position3d {
        return Position3d(x: lhs.x / rhs, y: lhs.y / rhs, z: lhs.z / rhs)
    }

    static func +=(lhs: inout Position3d, rhs: Position3d) {
        lhs = rhs + lhs
    }

    static func +=(lhs: inout Position3d, rhs: SIMD3<Float>) {
        lhs += Position3d(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
}

/// A vector consisting of three values
public typealias Vector3d = Position3d
/// A magnitude used to represent force or extent
public typealias Magnitude3d = Position3d
/// A size in the tri-dimensional coordinate space
public typealias Size3d = Position3d
/// A direction in a tri-dimensional coordinate space
public typealias Direction3d = Position3d
/// A rotation in a tri-dimensional coordinate space
public typealias Rotation3d = Position3d

/// Structure representing an RGBA color
public struct Color: ExpressibleByArrayLiteral {
    /// The red component of the target color
    public var r: Float
    /// The green component of the target color
    public var g: Float
    /// The blue component of the target color
    public var b: Float
    /// The alpha component of the target color
    public var a: Float = 1.0

    /// Default initializer for the Color class
    /// - Parameters:
    ///   - r: The red component of the target color
    ///   - g: The green component of the target color
    ///   - b: The blue component of the target color
    ///   - a: The alpha component of the target color
    public init(r: Float, g: Float, b: Float, a: Float = 1.0) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    /// Default initializer for the Color class
    /// - Parameters:
    ///   - r: The red component of the target color
    ///   - g: The green component of the target color
    ///   - b: The blue component of the target color
    ///   - a: The alpha component of the target color
    public init(_ r: Float, _ g: Float, _ b: Float, _ a: Float = 1.0) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    public init(arrayLiteral elements: Float...) {
        self.r = elements.count > 0 ? elements[0] : 0
        self.g = elements.count > 1 ? elements[1] : 0
        self.b = elements.count > 2 ? elements[2] : 0
        self.a = elements.count > 3 ? elements[3] : 1
    }

    /// A helper function to get a shade of white
    /// - Parameter val: The magnitude of white you want to get
    /// - Returns: A color where all values except alpha are `val`
    public static func shadeOfWhite(_ val: Float) -> Color {
        return Color(r: val, g: val, b: val)
    }

    /// A function that transforms a color to get a Metal-compliant type
    /// - Returns: A vector that contains the four values
    public func toSimd() -> SIMD4<Float> {
        return SIMD4<Float>(r, g, b, a)
    }

    /// A function that transforms a color to get a Metal-compliant type
    /// - Returns: A vector that contains only three values (ignoring alpha)
    public func toSimd3() -> SIMD3<Float> {
        return SIMD3<Float>(r, g, b)
    }
}

/// A struct that represents a vector of four values
public struct Vector4d: ExpressibleByArrayLiteral, Equatable {
    /// Value for the X value of the vector
    public var x: Float
    /// Value for the Y value of the vector
    public var y: Float
    /// Value for the Z value of the vector
    public var z: Float
    /// Value for the W value of the vector
    public var w: Float

    /// Explicit initializer for the Vector4d struct
    /// - Parameters:
    ///   - x: The value for the X value
    ///   - y: The value for the Y value
    ///   - z: The value for the Z value
    ///   - w: The value for the W value
    public init(x: Float = 0.0, y: Float = 0.0, z: Float = 0.0, w: Float = 1.0) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }

    /// Explicit initializer for the Vector4d struct
    /// - Parameters:
    ///   - x: The value for the X value
    ///   - y: The value for the Y value
    ///   - z: The value for the Z value
    ///   - w: The value for the W value
    public init(_ x: Float = 0.0, _ y: Float = 0.0, _ z: Float = 0.0, _ w: Float = 1.0) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }

    /// Initialization by array
    public init(arrayLiteral elements: Float...) {
        self.x = elements.count > 0 ? elements[0] : 0
        self.y = elements.count > 1 ? elements[1] : 0
        self.z = elements.count > 2 ? elements[2] : 0
        self.w = elements.count > 3 ? elements[3] : 1
    }

    /// Conforms to ExpressibleByArrayLiteral
    public typealias ArrayLiteralElement = Float

    /// A function that transforms a position to get a Metal-compliant type
    /// - Returns: A vector that contains the four values
    public func toSimd() -> simd_float4 {
        return simd_float4(x: x, y: y, z: z, w: w)
    }
}

public extension Vector4d {
    static func ==(lhs: Vector4d, rhs: Vector4d) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z && lhs.w == rhs.w
    }

    static func +(lhs: Vector4d, rhs: Vector4d) -> Vector4d {
        return Vector4d(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z, w: lhs.w + rhs.w)
    }

    static func -(lhs: Vector4d, rhs: Vector4d) -> Vector4d {
        return Vector4d(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z, w: lhs.w - rhs.w)
    }

    static func *(lhs: Vector4d, rhs: Float) -> Vector4d {
        return Vector4d(x: lhs.x * rhs, y: lhs.y * rhs, z: lhs.z * rhs, w: lhs.w * rhs)
    }

    static func /(lhs: Vector4d, rhs: Float) -> Vector4d {
        return Vector4d(x: lhs.x / rhs, y: lhs.y / rhs, z: lhs.z / rhs, w: lhs.w / rhs)
    }

    static func +=(lhs: inout Vector4d, rhs: Vector4d) {
        lhs = rhs + lhs
    }

    static func +=(lhs: inout Vector4d, rhs: SIMD4<Float>) {
        lhs += Vector4d(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z, w: lhs.w + rhs.w)
    }
}
