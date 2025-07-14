//
//  VectorModify.swift
//  Compose
//
//  Created by Max Van den Eynde on 14/7/25.
//

import Combine
import SwiftUI
import Tide

struct Vector3Input: Component {
    var title: String
    var value: Vector3d
    var components: [String]
    var onChange: (Vector3d) -> Void

    func render() -> any View {
        AnyView(Vector3InputView(title: title, value: value, components: components, onChange: onChange))
    }
}

extension View {
    func setCursor(cursor: NSCursor) -> some View {
        onHover { inside in
            if inside {
                cursor.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }
}

struct Vector3InputView: View {
    let components: [String]
    let title: String
    let onChange: (Vector3d) -> Void

    @State private var componentA: Float
    @State private var componentB: Float
    @State private var componentC: Float

    init(title: String, value: Vector3d, components: [String], onChange: @escaping (Vector3d) -> Void) {
        self._componentA = State(initialValue: value.x)
        self._componentB = State(initialValue: value.y)
        self._componentC = State(initialValue: value.z)
        self.components = components
        self.onChange = onChange
        self.title = title
    }

    var floatFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        formatter.minimumFractionDigits = 0
        formatter.allowsFloats = true
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }

    @GestureState private var dragOffset: CGSize = .zero
    @State private var initialValueA: Float = 0
    @State private var initialValueB: Float = 0
    @State private var initialValueC: Float = 0

    private var sensitivity: Float = 0.01

    var body: some View {
        VStack {
            HStack {
                Text(title.uppercased())
                    .fontWeight(.heavy)
                    .foregroundStyle(.secondary.opacity(0.5))
                    .font(.callout)
                Spacer()
            }
            HStack {
                Text("\(components[0]):")
                    .setCursor(cursor: .columnResize)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation
                            }
                            .onChanged { _ in
                                if dragOffset == .zero {
                                    initialValueA = componentA
                                }
                                let delta = Float(dragOffset.width)
                                componentA = initialValueA + delta * sensitivity
                            }
                    )

                TextField("", value: $componentA, formatter: floatFormatter)
                    .onChange(of: componentA) { notifyChange() }
            }

            HStack {
                Text("\(components[1]):")
                TextField("", value: $componentB, formatter: floatFormatter)
                    .onChange(of: componentB) { notifyChange() }
            }

            HStack {
                Text("\(components[2]):")
                TextField("", value: $componentC, formatter: floatFormatter)
                    .onChange(of: componentC) { notifyChange() }
            }
        }
    }

    func notifyChange() {
        onChange(Vector3d(x: componentA, y: componentB, z: componentC))
    }
}
