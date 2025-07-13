//
//  Bridging.swift
//  Compose
//
//  Created by Max Van den Eynde on 13/7/25.
//

/// Class that represents a object in a scene
public class Object<T> {
    /// The Core Object that depends of each renderer: Thyme, Arch or Trace
    public var coreObject: T
    /// The name of the object
    public var name: String

    public init(name: String, coreObject: T) {
        self.coreObject = coreObject
        self.name = name
    }
}
