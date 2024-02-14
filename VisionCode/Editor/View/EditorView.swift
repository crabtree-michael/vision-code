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
            EditorNavBar(state: self.state)
            
            if let activeIndex = state.activeIndex {
                ZStack {
                    ForEach(Array(zip(state.openFileStates.indices, state.openFileStates)),
                            id: \.0) { (index, fileState) in
                        FileView(state: fileState)
                            .opacity(activeIndex == index ? 1 : 0)
                    }
                    if let activeIndex = state.activeIndex {
                        VStack {
                            Spacer()
                            FileViewToolBar(
                                onSave: {
                                    if let index = state.activeIndex {
                                        state.openFileStates[index].onSave?()
                                    }
                                },
                                isWriting: state.openFileStates[activeIndex].isWriting,
                                language: $state.openFileStates[activeIndex].language)
                            .background(.clear)
                        }
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
