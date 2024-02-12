//
//  EditorView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI

struct Editor: View {
    @ObservedObject var state: EditorViewState
    
    init(state: EditorViewState) {
        self.state = state
    }
    
    var body: some View {
        VStack(spacing: 0) {
            EditorNavBar(activeIndex: self.$state.activeIndex,
                         openFiles: self.state.openFileStates,
                         title: self.state.title,
                         onSelected: self.state.onFileSelected,
                         onClose: self.state.onFileClose,
                         onQuickOpen: self.state.onQuickOpen)
            
            if let activeIndex = state.activeIndex {
                ZStack {
                    ForEach(Array(zip(state.openFileStates.indices, state.openFileStates)),
                            id: \.0) { (index, fileState) in
                        FileView(state: fileState)
                            .opacity(activeIndex == index ? 1 : 0)
                    }
                }
            } else {
                Spacer()
                Text("Open a file")
                Spacer()
            }
        }
        .background(.ultraThickMaterial)
        .onDisappear() {
            self.state.onClose?()
        }
        
    }
}
