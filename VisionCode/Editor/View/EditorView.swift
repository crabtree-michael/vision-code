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
                        VStack(spacing: 0) {
                            FileView(state: fileState)
                            FileViewToolBar(state: fileState)
                                .background(.clear)
                        }
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

#Preview {
    
    var fileState: FileViewState {
        let state = FileViewState(file: .init(path: "test"))
        state.isLoading = false
        state.content = longFile
        state.presentUnsavedChangesAlert = false
        state.findInFileState = .findAndReplace
        return state
    }
    
    var state: EditorViewState {
        let state = EditorViewState(title: "test")
        state.activeIndex = 0
        state.openFileStates = [fileState]
        return state
    }
    
    return Editor(state: state)
}
