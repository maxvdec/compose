//
//  Objects.swift
//  Compose
//
//  Created by Max Van den Eynde on 13/7/25.
//

import SwiftUI
import Thyme
import Tide

struct ObjectTreeView: View {
    @State private var objects: [Object<CoreObject>] = [
        Object(name: "Object A", coreObject: CoreObject(vertices: [])),
        Object(name: "Object B", coreObject: CoreObject(vertices: [])),
        Object(name: "Object C", coreObject: CoreObject(vertices: []))
    ]
    var body: some View {
        VStack {}.frame(maxWidth: 250, maxHeight: .infinity).glassEffect(in: .rect(cornerRadius: 16))
    }
}

#Preview {
    ObjectTreeView()
}
