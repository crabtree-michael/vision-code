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
                         openFiles: self.state.openFiles,
                         title: self.state.title,
                         onSelected: self.state.onFileSelected,
                         onClose: self.state.onFileClose)
            if let activeState = state.activeFileState {
                FileView(state: activeState)
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
