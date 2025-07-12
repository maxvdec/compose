//
//  ContentView.swift
//  Compose
//
//  Created by Max Van den Eynde on 12/7/25.
//

import SwiftUI
import Thyme
import Tide

struct ContentView: View {
    @StateObject var scene = ThymeScene()
    var body: some View {
        ZStack {
            ThymeView(scene: scene)
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack {
                Spacer()
                Button("Add Quad") {
                    let quad: [CoreVertex] = [
                        CoreVertex(position: Position3d(-0.5, 0.5, 0), color: Color(1, 0, 0, 1)), // Top-left
                        CoreVertex(position: Position3d(0.5, 0.5, 0), color: Color(0, 1, 0, 1)), // Top-right
                        CoreVertex(position: Position3d(0.5, -0.5, 0), color: Color(0, 0, 1, 1)), // Bottom-right
                        CoreVertex(position: Position3d(-0.5, -0.5, 0), color: Color(1, 1, 0, 1)) // Bottom-left
                    ]
                    let object = CoreObject(vertices: quad)
                    object.submitIndices(indices: [0, 1, 2, 0, 2, 3, 1])
                    scene.objects.append(object)
                }
            }
        }
    }
}
