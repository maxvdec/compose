//
//  Inspector.swift
//  Compose
//
//  Created by Max Van den Eynde on 14/7/25.
//

import SwiftUI

struct Inspector: View {
    @State private var modifiers: [any Modifier] = [
        UITestModifier()
    ]

    @State private var width: CGFloat = 250
    @State private var offsetX: CGFloat = 0

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.clear)
                .frame(width: 8)
                .opacity(0.0)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newWidth = width - value.translation.width
                            let clampedWidth = min(max(newWidth, 150), 600)

                            width = clampedWidth
                        }
                )
                .setCursor(cursor: .columnResize)

            VStack {
                ScrollView {
                    ForEach($modifiers, id: \.keyname) { $modifier in
                        VStack {
                            HStack {
                                if modifier.icon != nil {
                                    Image(systemName: modifier.icon!)
                                        .bold()
                                        .foregroundColor(.accentColor)
                                }
                                Text(modifier.name)
                                    .foregroundStyle(.secondary.opacity(0.6))
                                    .bold()
                                Spacer()
                            }
                            HStack {
                                AnyView(modifier.interface.render())
                                    .padding(.vertical, 2)
                                Spacer()
                            }
                            Divider()
                                .padding(.bottom, 10)
                        }.frame(minWidth: 220)
                    }
                }
                .padding()
            }
            .frame(width: width)
            .frame(minWidth: 250)
            .frame(maxHeight: .infinity)
            .glassEffect(in: .rect(cornerRadius: 16))
            .offset(x: offsetX)
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    Inspector()
}
