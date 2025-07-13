//
//  Modes.swift
//  Compose
//
//  Created by Max Van den Eynde on 13/7/25.
//

import SwiftUI

struct Modes: View {
    @State private var selection: String = "scene"
    var body: some View {
        GlassEffectContainer {
            HStack {
                Button {} label: {
                    Text("Scene")
                        .padding(.vertical, 4)
                        .padding(.horizontal, 30)
                }.padding(2).buttonStyle(.borderless).cornerRadius(8).glassEffect()
                Button("Hello") {}.padding(2).buttonStyle(GlassButtonStyle())
            }
        }
    }
}

#Preview {
    Modes()
        .frame(maxWidth: .infinity)
}
