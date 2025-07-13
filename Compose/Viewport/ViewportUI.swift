//
//  Main.swift
//  Compose
//
//  Created by Max Van den Eynde on 13/7/25.
//

import SwiftUI

struct MainUI: View {
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
            Text("Hello")
                .frame(maxWidth: 250, maxHeight: .infinity)
        }
    }
}
