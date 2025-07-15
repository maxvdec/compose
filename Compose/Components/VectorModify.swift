//
//  VectorModify.swift
//  Compose
//
//  Created by Max Van den Eynde on 14/7/25.
//

import Combine
import SwiftUI
import Tide

/// Conditions to warn for extreme values
struct Vector3AxisWarning {
    var x: Bool
    var xMessage: String = ""
    var y: Bool
    var yMessage: String = ""
    var z: Bool
    var zMessage: String = ""
}

/// View that configures a Vector3d
struct Vector3Input: Component {
    var title: String
    var value: Vector3d
    var components: [String]
    var onChange: (Vector3d) -> Void
    var units: String = ""
    var isWarning: (Vector3d) -> Vector3AxisWarning = { _ in
        Vector3AxisWarning(x: false, y: false, z: false)
    }

    func render() -> any View {
        AnyView(Vector3InputView(title: title, value: value, components: components, onChange: onChange, isWarning: isWarning, units: units))
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
    let charactersToShow: Int = 5
    let units: String
    let isWarning: (Vector3d) -> Vector3AxisWarning

    @State private var componentA: Float
    @State private var componentB: Float
    @State private var componentC: Float

    @GestureState private var dragOffset: CGSize = .zero
    @State private var initialValueA: Float = 0
    @State private var initialValueB: Float = 0
    @State private var initialValueC: Float = 0

    @State private var warningA: Bool = false
    @State private var warningB: Bool = false
    @State private var warningC: Bool = false
    @State private var warningMessageA: String = ""
    @State private var warningMessageB: String = ""
    @State private var warningMessageC: String = ""

    private var sensitivity: Float = 0.01

    init(title: String, value: Vector3d, components: [String], onChange: @escaping (Vector3d) -> Void, isWarning: @escaping (Vector3d) -> Vector3AxisWarning, units: String) {
        self._componentA = State(initialValue: value.x)
        self._componentB = State(initialValue: value.y)
        self._componentC = State(initialValue: value.z)
        self.components = components
        self.onChange = onChange
        self.title = title
        self.isWarning = isWarning
        let initialWarnings = isWarning(value)
        self._warningA = State(initialValue: initialWarnings.x)
        self._warningB = State(initialValue: initialWarnings.y)
        self._warningC = State(initialValue: initialWarnings.z)
        self._warningMessageA = State(initialValue: initialWarnings.xMessage)
        self._warningMessageB = State(initialValue: initialWarnings.yMessage)
        self._warningMessageC = State(initialValue: initialWarnings.zMessage)
        self.units = units
    }

    func estimatedWidth(forCharacters count: Int) -> CGFloat {
        let charWidth: CGFloat = 10
        return CGFloat(count) * charWidth + 20
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title.uppercased())
                    .fontWeight(.heavy)
                    .foregroundStyle(.secondary.opacity(0.5))
                    .font(.callout)
                Spacer()
            }

            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let textFieldWidth = estimatedWidth(forCharacters: charactersToShow)
                let labelWidth: CGFloat = 20
                let horizontalSpacing: CGFloat = 10
                let totalRequiredWidth = (labelWidth + horizontalSpacing + textFieldWidth) * 3 + horizontalSpacing * 2

                if totalRequiredWidth <= availableWidth {
                    HStack(spacing: horizontalSpacing) {
                        vectorComponentInput(index: 0, componentValue: $componentA, warning: warningA, warningMessage: warningMessageA) { value in
                            if dragOffset == .zero { initialValueA = componentA }
                            componentA = initialValueA + Float(value.translation.width) * sensitivity
                        }
                        .frame(width: labelWidth + textFieldWidth + horizontalSpacing)

                        vectorComponentInput(index: 1, componentValue: $componentB, warning: warningB, warningMessage: warningMessageB) { value in
                            if dragOffset == .zero { initialValueB = componentB }
                            componentB = initialValueB + Float(value.translation.width) * sensitivity
                        }
                        .frame(width: labelWidth + textFieldWidth + horizontalSpacing)

                        vectorComponentInput(index: 2, componentValue: $componentC, warning: warningC, warningMessage: warningMessageC) { value in
                            if dragOffset == .zero { initialValueC = componentC }
                            componentC = initialValueC + Float(value.translation.width) * sensitivity
                        }
                        .frame(width: labelWidth + textFieldWidth + horizontalSpacing)
                    }
                    .onChange(of: componentA) { _, _ in notifyChange() }
                    .onChange(of: componentB) { _, _ in notifyChange() }
                    .onChange(of: componentC) { _, _ in notifyChange() }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        vectorComponentInput(index: 0, componentValue: $componentA, warning: warningA, warningMessage: warningMessageA) { value in
                            if dragOffset == .zero { initialValueA = componentA }
                            componentA = initialValueA + Float(value.translation.width) * sensitivity
                        }

                        vectorComponentInput(index: 1, componentValue: $componentB, warning: warningB, warningMessage: warningMessageB) { value in
                            if dragOffset == .zero { initialValueB = componentB }
                            componentB = initialValueB + Float(value.translation.width) * sensitivity
                        }

                        vectorComponentInput(index: 2, componentValue: $componentC, warning: warningC, warningMessage: warningMessageC) { value in
                            if dragOffset == .zero { initialValueC = componentC }
                            componentC = initialValueC + Float(value.translation.width) * sensitivity
                        }
                    }
                    .onChange(of: componentA) { _, _ in notifyChange() }
                    .onChange(of: componentB) { _, _ in notifyChange() }
                    .onChange(of: componentC) { _, _ in notifyChange() }
                }
            }
            .frame(height: 100)
        }
    }

    @ViewBuilder
    func vectorComponentInput(index: Int, componentValue: Binding<Float>, warning: Bool, warningMessage: String, onDrag: @escaping (DragGesture.Value) -> Void) -> some View {
        HStack {
            Text("\(components[index]):")
                .frame(width: 20, alignment: .leading)
                .setCursor(cursor: .columnResize)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                            onDrag(value)
                        }
                )

            ZStack {
                TextField("", value: componentValue, formatter: floatFormatter)
                    .frame(minWidth: estimatedWidth(forCharacters: charactersToShow), maxWidth: .infinity)

                if warning && !warningMessage.isEmpty {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.yellow.opacity(0.9))
                        .frame(minWidth: estimatedWidth(forCharacters: charactersToShow), maxWidth: .infinity)
                        .overlay(
                            Text(warningMessage)
                                .foregroundColor(.white)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(2)
                        )
                }
            }

            if warning {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
            }
        }
    }

    var floatFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        formatter.minimumFractionDigits = 0
        formatter.allowsFloats = true
        formatter.locale = Locale(identifier: "en_US")
        formatter.usesGroupingSeparator = false
        formatter.positiveSuffix = units
        formatter.negativeSuffix = units
        return formatter
    }

    func notifyChange() {
        let newValue = Vector3d(x: componentA, y: componentB, z: componentC)
        let warnings = isWarning(newValue)

        warningA = warnings.x
        warningB = warnings.y
        warningC = warnings.z

        warningMessageA = warnings.xMessage
        warningMessageB = warnings.yMessage
        warningMessageC = warnings.zMessage

        onChange(newValue)
    }
}

struct Vector4AxisWarning {
    var x: Bool
    var xMessage: String = ""
    var y: Bool
    var yMessage: String = ""
    var z: Bool
    var zMessage: String = ""
    var w: Bool
    var wMessage: String = ""
}

/// View to change a Vector4d Input
struct Vector4Input: Component {
    var title: String
    var value: Vector4d
    var components: [String]
    var onChange: (Vector4d) -> Void
    var units: String = ""
    var isWarning: (Vector4d) -> Vector4AxisWarning = { _ in
        Vector4AxisWarning(x: false, y: false, z: false, w: false)
    }

    func render() -> any View {
        AnyView(Vector4InputView(title: title, value: value, components: components, onChange: onChange, isWarning: isWarning, units: units))
    }
}

struct Vector4InputView: View {
    let components: [String]
    let title: String
    let onChange: (Vector4d) -> Void
    let charactersToShow: Int = 5
    let isWarning: (Vector4d) -> Vector4AxisWarning
    let units: String

    @State private var componentA: Float
    @State private var componentB: Float
    @State private var componentC: Float
    @State private var componentD: Float

    @GestureState private var dragOffset: CGSize = .zero
    @State private var initialValueA: Float = 0
    @State private var initialValueB: Float = 0
    @State private var initialValueC: Float = 0
    @State private var initialValueD: Float = 0

    @State private var warningA: Bool = false
    @State private var warningB: Bool = false
    @State private var warningC: Bool = false
    @State private var warningD: Bool = false
    @State private var warningMessageA: String = ""
    @State private var warningMessageB: String = ""
    @State private var warningMessageC: String = ""
    @State private var warningMessageD: String = ""

    private var sensitivity: Float = 0.01

    init(title: String, value: Vector4d, components: [String], onChange: @escaping (Vector4d) -> Void, isWarning: @escaping (Vector4d) -> Vector4AxisWarning, units: String) {
        self._componentA = State(initialValue: value.x)
        self._componentB = State(initialValue: value.y)
        self._componentC = State(initialValue: value.z)
        self._componentD = State(initialValue: value.w)
        self.components = components
        self.onChange = onChange
        self.title = title
        self.isWarning = isWarning
        let initialWarnings = isWarning(value)
        self._warningA = State(initialValue: initialWarnings.x)
        self._warningB = State(initialValue: initialWarnings.y)
        self._warningC = State(initialValue: initialWarnings.z)
        self._warningD = State(initialValue: initialWarnings.w)
        self._warningMessageA = State(initialValue: initialWarnings.xMessage)
        self._warningMessageB = State(initialValue: initialWarnings.yMessage)
        self._warningMessageC = State(initialValue: initialWarnings.zMessage)
        self._warningMessageD = State(initialValue: initialWarnings.wMessage)
        self.units = units
    }

    func estimatedWidth(forCharacters count: Int) -> CGFloat {
        let charWidth: CGFloat = 10
        return CGFloat(count) * charWidth + 20
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title.uppercased())
                    .fontWeight(.heavy)
                    .foregroundStyle(.secondary.opacity(0.5))
                    .font(.callout)
                Spacer()
            }

            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let textFieldWidth = estimatedWidth(forCharacters: charactersToShow)
                let labelWidth: CGFloat = 20
                let horizontalSpacing: CGFloat = 10
                let totalRequiredWidth = (labelWidth + horizontalSpacing + textFieldWidth) * 4 + horizontalSpacing * 3

                if totalRequiredWidth <= availableWidth {
                    HStack(spacing: horizontalSpacing) {
                        vectorComponentInput(index: 0, componentValue: $componentA, warning: warningA, warningMessage: warningMessageA) { value in
                            if dragOffset == .zero { initialValueA = componentA }
                            componentA = initialValueA + Float(value.translation.width) * sensitivity
                        }
                        .frame(width: labelWidth + textFieldWidth + horizontalSpacing)

                        vectorComponentInput(index: 1, componentValue: $componentB, warning: warningB, warningMessage: warningMessageB) { value in
                            if dragOffset == .zero { initialValueB = componentB }
                            componentB = initialValueB + Float(value.translation.width) * sensitivity
                        }
                        .frame(width: labelWidth + textFieldWidth + horizontalSpacing)

                        vectorComponentInput(index: 2, componentValue: $componentC, warning: warningC, warningMessage: warningMessageC) { value in
                            if dragOffset == .zero { initialValueC = componentC }
                            componentC = initialValueC + Float(value.translation.width) * sensitivity
                        }
                        .frame(width: labelWidth + textFieldWidth + horizontalSpacing)

                        vectorComponentInput(index: 3, componentValue: $componentD, warning: warningD, warningMessage: warningMessageD) { value in
                            if dragOffset == .zero { initialValueD = componentD }
                            componentD = initialValueD + Float(value.translation.width) * sensitivity
                        }
                        .frame(width: labelWidth + textFieldWidth + horizontalSpacing)
                    }
                    .onChange(of: componentA) { _, _ in notifyChange() }
                    .onChange(of: componentB) { _, _ in notifyChange() }
                    .onChange(of: componentC) { _, _ in notifyChange() }
                    .onChange(of: componentD) { _, _ in notifyChange() }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        vectorComponentInput(index: 0, componentValue: $componentA, warning: warningA, warningMessage: warningMessageA) { value in
                            if dragOffset == .zero { initialValueA = componentA }
                            componentA = initialValueA + Float(value.translation.width) * sensitivity
                        }

                        vectorComponentInput(index: 1, componentValue: $componentB, warning: warningB, warningMessage: warningMessageB) { value in
                            if dragOffset == .zero { initialValueB = componentB }
                            componentB = initialValueB + Float(value.translation.width) * sensitivity
                        }

                        vectorComponentInput(index: 2, componentValue: $componentC, warning: warningC, warningMessage: warningMessageC) { value in
                            if dragOffset == .zero { initialValueC = componentC }
                            componentC = initialValueC + Float(value.translation.width) * sensitivity
                        }

                        vectorComponentInput(index: 3, componentValue: $componentD, warning: warningD, warningMessage: warningMessageD) { value in
                            if dragOffset == .zero { initialValueD = componentD }
                            componentD = initialValueD + Float(value.translation.width) * sensitivity
                        }
                    }
                    .onChange(of: componentA) { _, _ in notifyChange() }
                    .onChange(of: componentB) { _, _ in notifyChange() }
                    .onChange(of: componentC) { _, _ in notifyChange() }
                    .onChange(of: componentD) { _, _ in notifyChange() }
                }
            }
            .frame(height: 120)
        }
    }

    @ViewBuilder
    func vectorComponentInput(index: Int, componentValue: Binding<Float>, warning: Bool, warningMessage: String, onDrag: @escaping (DragGesture.Value) -> Void) -> some View {
        HStack {
            Text("\(components[index]):")
                .frame(width: 20, alignment: .leading)
                .setCursor(cursor: .columnResize)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                            onDrag(value)
                        }
                )

            ZStack {
                TextField("", value: componentValue, formatter: floatFormatter)
                    .frame(minWidth: estimatedWidth(forCharacters: charactersToShow), maxWidth: .infinity)

                if warning && !warningMessage.isEmpty {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.yellow.opacity(0.9))
                        .frame(minWidth: estimatedWidth(forCharacters: charactersToShow), maxWidth: .infinity)
                        .overlay(
                            Text(warningMessage)
                                .foregroundColor(.white)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(2)
                        )
                }
            }

            if warning {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
            }
        }
    }

    var floatFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        formatter.minimumFractionDigits = 0
        formatter.allowsFloats = true
        formatter.locale = Locale(identifier: "en_US")
        formatter.usesGroupingSeparator = false
        formatter.positiveSuffix = units
        formatter.negativeSuffix = units
        return formatter
    }

    func notifyChange() {
        let newValue = Vector4d(x: componentA, y: componentB, z: componentC, w: componentD)
        let warnings = isWarning(newValue)

        warningA = warnings.x
        warningB = warnings.y
        warningC = warnings.z
        warningD = warnings.w

        warningMessageA = warnings.xMessage
        warningMessageB = warnings.yMessage
        warningMessageC = warnings.zMessage
        warningMessageD = warnings.wMessage

        onChange(newValue)
    }
}
