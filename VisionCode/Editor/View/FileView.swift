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
        VStack {
            if state.isLoading {
                ProgressView()
            } else {
                TextEditor(text: $state.content)
                    .font(.system(size: 14))
                if !state.isWriting {
                    Button {
                        state.onSave?()
                    } label: {
                        Text("Save")
                    }
                } else {
                    ProgressView()
                }
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
