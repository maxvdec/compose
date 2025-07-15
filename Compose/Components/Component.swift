//
//  Component.swift
//  Compose
//
//  Created by Max Van den Eynde on 14/7/25.
//

import SwiftUI
import Tide

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
        return AnyView(Spacer())
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

    // Other text customizes
    private var textColor: SwiftUI.Color = .black
    private var bold: Bool = false

    init(_ contents: String) {
        self.contents = contents
    }

    func render() -> any View {
        AnyView(ZStack {
            if backgroundStyle == .background {
                RoundedRectangle(cornerRadius: 10)
                    .opacity(0.2)
            } else if backgroundStyle == .warning {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.yellow)
                    .opacity(0.2)
            } else if backgroundStyle == .error {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.red)
                    .opacity(0.2)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .opacity(0)
            }
            Text(contents)
                .foregroundStyle(textColor)
                .bold(bold)
                .padding(6)
        })
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
        copy.textColor = .brown.opacity(0.7)
        copy.bold = true
        return copy
    }

    /// Enable the error style for the user
    /// - Returns: A copy of the view depicting an error
    func error() -> UIText {
        var copy = self
        copy.backgroundStyle = .error
        copy.textColor = .red
        copy.bold = true
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

    static subscript(_ content: any Component...) -> some View {
        let views = content.map { AnyView($0.render()) }
        return VStack {
            ForEach(0 ..< views.count, id: \.self) { index in
                views[index]
            }
        }
    }

    func render() -> any View {
        let views = content().map { AnyView($0.render()) }
        return AnyView(VStack {
            ForEach(0 ..< views.count, id: \.self) { index in
                views[index]
            }
        })
    }
}

struct Section: Component {
    let title: String
    @ComponentBuilder var content: () -> [any Component]
    @State private var isExpanded: Bool = true

    static func make(title: String, @ComponentBuilder _ content: @escaping () -> [any Component]) -> some View {
        AnyView(_SectionView(title: title, content: content))
    }

    func render() -> any View {
        AnyView(_SectionView(title: title, content: content))
    }
}

struct Row: Component {
    @ComponentBuilder var content: () -> [any Component]
    @State private var isExpanded: Bool = true

    static func make(title: String, @ComponentBuilder _ content: @escaping () -> [any Component]) -> some View {
        let components = content()
        return AnyView(HStack {
            ForEach(0 ..< components.count, id: \.self) { index in
                components[index].render() as! AnyView
            }
        })
    }

    func render() -> any View {
        let components = content()
        return AnyView(HStack {
            ForEach(0 ..< components.count, id: \.self) { index in
                components[index].render() as! AnyView
            }
        })
    }
}

struct Column: Component {
    @ComponentBuilder var content: () -> [any Component]
    @State private var isExpanded: Bool = true

    static func make(title: String, @ComponentBuilder _ content: @escaping () -> [any Component]) -> some View {
        let components = content()
        return AnyView(VStack(alignment: .leading) {
            ForEach(0 ..< components.count, id: \.self) { index in
                components[index].render() as! AnyView
            }
        })
    }

    func render() -> any View {
        let components = content()
        return AnyView(VStack(alignment: .leading) {
            ForEach(0 ..< components.count, id: \.self) { index in
                components[index].render() as! AnyView
            }
        })
    }
}

private struct _SectionView: View {
    let title: String
    let content: () -> [any Component]
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: {
                isExpanded.toggle()
            }) {
                HStack {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    Text(title)
                        .bold()
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 3)
            .padding(.vertical, 3)

            if isExpanded {
                let components = content()
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(0 ..< components.count, id: \.self) { index in
                        components[index].render() as! AnyView
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
