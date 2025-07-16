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
                .onAppear {
                    let object = try! CoreObject.loadModel(from: Bundle.main.url(forResource: "teapot", withExtension: "obj")!)
                    object.position = Position3d(0, 0, -1)
                    scene.camera.move(to: Position3d(0, 5, 15))
                    print("Teapot ID: \(object.id), Position: \(object.position)")
                    scene.addObject(object)

                    let box = CoreObject.box()
                    box.position = Position3d(0, -4, 3)
                    print("Box ID: \(box.id), Position: \(box.position)")
                    scene.addObject(box)
                }
            MainUI(scene: scene)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
