//
//  Modes.swift
//  Compose
//
//  Created by Max Van den Eynde on 13/7/25.
//

import SwiftUI

/// Change of selection between viewing modes
struct Modes: View {
    @State private var selection: String = "scene"
    var body: some View {
        GlassEffectContainer {
            HStack {
                Button(action: { selection = "scene" }) {
                    Text("Scene")
                        .padding(.vertical, 4)
                        .padding(.horizontal, 25)
                        .background(selection == "scene" ? Color.secondary.opacity(0.2) : Color.clear)
                        .cornerRadius(10)
                }.padding(2).buttonStyle(.borderless).glassEffect()
                Button(action: { selection = "material" }) {
                    Text("Material")
                        .padding(.vertical, 4)
                        .padding(.horizontal, 25)
                        .background(selection == "material" ? Color.secondary.opacity(0.2) : Color.clear)
                        .cornerRadius(10)
                }.padding(2).buttonStyle(.borderless).glassEffect()
                Button(action: { selection = "compute" }) {
                    Text("Compute")
                        .padding(.vertical, 4)
                        .padding(.horizontal, 25)
                        .background(selection == "compute" ? Color.secondary.opacity(0.2) : Color.clear)
                        .cornerRadius(10)
                }.padding(2).buttonStyle(.borderless).glassEffect()
            }.padding(.horizontal, 4).padding(.vertical, 4).background {
                RoundedRectangle(cornerRadius: 20)
                    .foregroundStyle(.white).shadow(color: .secondary.opacity(0.4), radius: 8)
            }
        }
    }
}

#Preview {
    Modes()
        .frame(maxWidth: .infinity)
        .padding()
}
