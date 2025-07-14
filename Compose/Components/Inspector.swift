//
//  Inspector.swift
//  Compose
//
//  Created by Max Van den Eynde on 14/7/25.
//

import SwiftUI

/// Inspector view to change properties of a concrete object
struct Inspector: View {
    @State private var modifiers: [any Modifier] = [
        UITestModifier()
    ]
    var body: some View {
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
                    }
                }
            }.padding()
        }.frame(maxWidth: 250, maxHeight: .infinity).glassEffect(in: .rect(cornerRadius: 16))
    }
}

#Preview {
    Inspector()
}
