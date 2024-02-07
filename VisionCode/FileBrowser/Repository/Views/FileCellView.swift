//
//  FileCellView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI

struct FileCellView: View {
    @ObservedObject var state: FileCellViewState
    let indentationLevel: Int
    
    var empty: Bool {
        return state.subnodes.isEmpty
    }
    
    @State var collapsed: Bool
    
    var onOpen: FileLambda?  = nil
    
    var body: some View {
        LazyVStack(spacing: 16) {
            HStack {
                Spacer(minLength: 12 * CGFloat(indentationLevel))
                HStack(alignment: .center) {
                    Spacer()
                    if (!state.loaded) {
                        ProgressView()
                            .frame(maxHeight: 0)
                            .scaleEffect(CGSize(width: 0.4, height: 0.4))
                        
                    } else if (!empty) {
                        Image(systemName: !collapsed ? "chevron.down" : "chevron.right")
                    } else {
                        Image(systemName: state.file.icon.rawValue)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: 12)
                Text(state.file.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            if (!empty && !collapsed && state.loaded) {
                ForEach(state.subnodes, id: \.file.path) { state in
                    FileCellView(state: state,
                                 indentationLevel: indentationLevel + 1,
                                 collapsed: true,
                                 onOpen: self.onOpen)
                }
            }
        }
        .hoverEffect()
        .onTapGesture {
            guard state.loaded else {
                return
            }
            guard !empty else {
                self.onOpen?(state.file)
                return
            }
            
            self.collapsed = !self.collapsed
        }
    }
}

#Preview {
    var state: FileCellViewState {
        let root = PathNode(file: File(path: "test/"), 
                            subnodes:
                                [PathNode(file: File(path: "test/green.txt"), subnodes: []),
                                 PathNode(file: File(path: "test/green2.txt"), subnodes: []),
                                 PathNode(file: File(path: "test/blue.txt"), subnodes: [], loaded: true),
                                  PathNode(file: File(path: "test/blue2.txt"), subnodes: [], loaded: true)]
                            )
        root.loaded = true
        return FileCellViewState(node: root)
    }
    
    return FileCellView(state: state,
                 indentationLevel: 1,
                 collapsed: false,
                 onOpen: nil)
}
