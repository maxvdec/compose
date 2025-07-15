//
//  Main.swift
//  Compose
//
//  Created by Max Van den Eynde on 13/7/25.
//

import SwiftUI
import Thyme

/// The main UI for Compose
struct MainUI: View {
    @ObservedObject var scene: ThymeScene
    var body: some View {
        HStack {
            ObjectTreeView()
                .padding()
            Spacer()
            VStack {
                Modes()
                    .padding()
                Spacer()
            }
            Spacer()
            Inspector(scene: scene)
                .padding()
        }
    }
}
