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
                Button("Add Teapot") {
                    let object = try! CoreObject.loadModel(from: Bundle.main.url(forResource: "teapot", withExtension: "obj")!)
                    scene.objects.append(object)
                }
            }
        }
    }
}
