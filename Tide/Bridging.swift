//
//  Bridging.swift
//  Compose
//
//  Created by Max Van den Eynde on 13/7/25.
//

import Combine
import SwiftUI

/// Class that represents a object in a scene
public class Object<T: Equatable>: ObservableObject, Equatable {
    public static func == (lhs: Object<T>, rhs: Object<T>) -> Bool {
        return lhs.coreObject == rhs.coreObject
    }
    
    /// The Core Object that depends of each renderer: Thyme, Arch or Trace
    @Published public var coreObject: T
    /// The name of the object
    public var name: String

    public init(name: String, coreObject: T) {
        self.coreObject = coreObject
        self.name = name
    }
}
