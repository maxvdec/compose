//
//  Component.swift
//  Compose
//
//  Created by Max Van den Eynde on 14/7/25.
//

import SwiftUI

/// Component in an inspector's UI
public protocol Component {
    func render() -> any View
}

/// Modifier that changes the object properties
public protocol Modifier {
    /// The main UI Interface to change modifier's properties
    var interface: any Component { get }
    /// The display name of the modifier
    var name: String { get }
    /// The optional SF Symbols Symbol name for the modifier
    var icon: String? { get }
    /// A unique identifier to detect the modifier
    var keyname: String { get }
}

/// Simple padding component for UI
struct Padding: Component {
    func render() -> any View {
        return Spacer()
    }
}

/// Text that can be used to display information to the user
struct UIText: Component {
    /// The style of the text
    private enum Style {
        case background
        case warning
        case none
        case error
    }

    /// The contents that the text displays
    var contents: String
    /// The style in which the text is depicted
    private var backgroundStyle: Style = .background

    init(_ contents: String) {
        self.contents = contents
    }

    func render() -> any View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .opacity(0.2)
            Text(contents)
                .padding(6)
        }
    }

    /// Disable the default background of the text
    /// - Returns: A copy of the view with no background
    func noBackground() -> UIText {
        var copy = self
        copy.backgroundStyle = .none
        return copy
    }

    /// Enable the warning style for the user
    /// - Returns: A copy of the view depicting a warning
    func warning() -> UIText {
        var copy = self
        copy.backgroundStyle = .warning
        return copy
    }

    /// Enable the error style for the user
    /// - Returns: A copy of the view depicting an error
    func error() -> UIText {
        var copy = self
        copy.backgroundStyle = .error
        return copy
    }
}

@resultBuilder
struct ComponentBuilder {
    static func buildBlock(_ components: [any Component]...) -> [any Component] {
        components.flatMap { $0 }
    }

    static func buildExpression(_ expression: any Component) -> [any Component] {
        [expression]
    }

    static func buildOptional(_ component: [any Component]?) -> [any Component] {
        component ?? []
    }

    static func buildEither(first component: [any Component]) -> [any Component] {
        component
    }

    static func buildEither(second component: [any Component]) -> [any Component] {
        component
    }
}

struct ConfigureView: Component {
    @ComponentBuilder var content: () -> [any Component]

    static subscript(_ content: any Component...) -> any View {
        let views = content.map { AnyView($0.render()) }
        return VStack {
            ForEach(0 ..< views.count, id: \.self) { index in
                views[index]
            }
        }
    }

    func render() -> any View {
        let views = content().map { AnyView($0.render()) }
        return VStack {
            ForEach(0 ..< views.count, id: \.self) { index in
                views[index]
            }
        }
    }
}
