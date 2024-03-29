//
//  FileView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI
import CodeEditLanguages

struct FileView: View {
    @ObservedObject var state: FileViewState
    var isVisible: Bool
    
    var isShowingError:Binding<Bool> {
        Binding {
            state.error != nil
        } set: { _ in
            state.error = nil
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if state.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ZStack{
                    VCTextEditor(text: $state.content,
                                 language: $state.language,
                                 findInFileState: $state.findInFileState,
                                 tabWidth: $state.tabWidth,
                                 isVisible: isVisible)
                }
            }
        }
        .alert(isPresented: isShowingError, error: state.error) { _ in
            
        } message: { error in
            if let description = error.errorDescription {
                Text(description)
            }
        }
        .alert(.init("Unsaved Changes"), isPresented: $state.presentUnsavedChangesAlert, actions: {
            Button {
                state.onSaveAndClose?()
            } label: {
                Text("Save & Close")
            }
            Button(role: .destructive) {
                state.onForceClose?()
            } label: {
                Text("Discard Changes")
            }

        })
        .alert(.init("Remote Modified"), isPresented: $state.presentRemoteModifiedAlert, actions: {
            Button {
                state.onOverwriteRemote?()
            } label: {
                Text("Overwrite")
            }
            Button(role: .destructive) {
                state.onReloadRemote?()
            } label: {
                Text("Discard Changes")
            }
        })
        .frame(maxWidth: .infinity)
        .background(Color(.darkGray))
    }
}

#Preview {
    
    var state: FileViewState {
        let state = FileViewState(file: .init(path: "test"))
        state.isLoading = false
        state.content = longFile
        state.presentUnsavedChangesAlert = false
        state.findInFileState = .findAndReplace
        return state
    }
    
    return FileView(state: state, isVisible: true)
}
