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
        LazyVStack(spacing: 8) {
            HStack {
                Spacer(minLength: 12 * CGFloat(indentationLevel))
                HStack {
                    Spacer()
                    if (!state.loaded) {
                        ProgressView()
                            .padding()
                            .scaleEffect(CGSize(width: 0.5, height: 0.5))
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
            .hoverEffect()
            .onTapGesture {
                guard state.loaded else {
                    print("Not loaded")
                    return
                }
                guard !empty else {
                    self.onOpen?(state.file)
                    return
                }
                
                print("Collapsing")
                self.collapsed = !self.collapsed
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
    }
}
