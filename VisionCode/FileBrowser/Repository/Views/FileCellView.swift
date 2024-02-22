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
    var onReloadDirectory: FileLambda? = nil
    
    func onTap() {
        guard state.loaded else {
            return
        }
        guard !empty else {
            self.onOpen?(state.file)
            return
        }
        
        self.collapsed = !self.collapsed
    }
    
    var menuItems: some View {
        Group {
            Button {
                self.onTap()
            } label: {
                if !empty && !collapsed {
                    Label("Close", systemImage: "eye.slash")
                } else {
                    Label("Open", systemImage: "eye")
                }
                
            }
            if !empty {
                Button {
                    self.onReloadDirectory?(state.file)
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
            }
        }
    }
    
    var body: some View {
        LazyVStack(spacing: 4) {
            ZStack {
                Color.black.opacity(0.0001)
                    .frame(minHeight: 48)
                HStack {
                    Color.black.opacity(0.0001)
                        .frame(maxWidth: 12 * CGFloat(indentationLevel))
                    HStack(alignment: .center) {
                        if (!state.loaded) {
                            ProgressView()
                                .frame(maxHeight: 0)
                                .scaleEffect(CGSize(width: 0.4, height: 0.4))
                            
                        } else if (!empty) {
                            Image(systemName: !collapsed ? "chevron.down" : "chevron.right")
                        } else {
                            Image(systemName: state.file.icon.rawValue)
                        }
                        
                    }
                    .frame(maxWidth: 12)
                    Text(state.file.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                }
            }
            .onTapGesture {
                self.onTap()
            }
            .contextMenu(ContextMenu(menuItems: {
                menuItems
            }))
            if (!empty && !collapsed && state.loaded) {
                ForEach(state.subnodes, id: \.file.path) { state in
                    FileCellView(state: state,
                                 indentationLevel: indentationLevel + 1,
                                 collapsed: true,
                                 onOpen: self.onOpen,
                                 onReloadDirectory: self.onReloadDirectory)
                }
            }
        }
        .hoverEffect()
    }
}

#Preview {
    var state: FileCellViewState {
        let root = PathNode(file: File(path: "test/"), 
                            subnodes:
                                [PathNode(file: File(path: "test/green.txt"), subnodes: []),
                                 PathNode(file: File(path: "test/green2.txt"), subnodes: []),
                                 PathNode(file: File(path: "test/blue.txt"), subnodes: [], loaded: true),
                                  PathNode(file: File(path: "test/blue2asdflajsdfaslkdf.txt"), subnodes: [], loaded: true)]
                            )
        root.loaded = true
        return FileCellViewState(node: root)
    }
    
    return FileCellView(state: state,
                 indentationLevel: 0,
                 collapsed: false,
                 onOpen: nil)
}
