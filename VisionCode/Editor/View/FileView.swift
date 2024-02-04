//
//  FileView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI

struct FileView: View {
    @ObservedObject var state: FileViewState
    
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
                VCTextEditor(text: $state.content)
                FileViewToolBar(state: state)
            }
        }
        .alert(isPresented: isShowingError, error: state.error) { _ in
            
        } message: { error in
            if let description = error.errorDescription {
                Text(description)
            }
        }
    }
}

#Preview {
    
    var state: FileViewState {
        let state = FileViewState()
        state.isLoading = false
        state.content = longFile
        return state
    }
    
    return FileView(state: state)
}
