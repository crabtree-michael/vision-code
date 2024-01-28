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
                VCTextEditor(text: $state.content)
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

#Preview {
    
    var state: FileViewState {
        let state = FileViewState()
        state.isLoading = false
        state.content = """
//
//  DocumentView.swift
//  SwiftUITextEditor
//
//  Created by mark on 12/18/19.
//  Copyright © 2019 Swift Dev Journal. All rights reserved.
//

import SwiftUI

struct DocumentView: View {
    @State var document: Document
    var dismiss: () -> Void

    var body: some View {
        VStack {
            HStack {
                Text("File Name")
                    .foregroundColor(.secondary)

                Text(document.fileURL.lastPathComponent) laskjdflaksjdflaksdjflaksdjflaksjdflaksjdflkajsdlfkjasdlfkjasldkfjalskdfjlaskdjflaskdjflaksdjflaksjdflkasjdflkjasdf
            }
            TextView(document: $document)
            Button("Done", action: dismiss)
        }
    }
}







Now this is really long!

Can you see me?

oh you can't
"""
        return state
    }
    
    return FileView(state: state)
}
