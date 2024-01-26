//
//  RepositoryView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI

struct RepositoryView: View {
    @ObservedObject var state: RepositoryViewState
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                RepositoryFilesView(state: self.state.browserState)
                    .padding(.leading)
                    .padding(.top)
                    .padding(.bottom)
                Editor(state: state.editorState)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThickMaterial)
            }
        }
        .onDisappear {
            self.state.onClose?()
        }
    }
}


#Preview {
    var root: PathNode {
        let file1 = File(path: "/michael/george/test.txt", isFolder: false)
        let file2 = File(path: "/michael/george/long.txt", isFolder: false)
        let file3 = File(path: "/michael/smith/john/text.txt", isFolder: false)
        let file4 = File(path: "/michael/smith/text.txt", isFolder: false)
        let file5 = File(path: "/michael/test.txt", isFolder: false)
        
        return PathNode(file: File(path: "/michael"), subnodes: [
            PathNode(file: File(path: "/michael/george", icon: .folder, isFolder: true), subnodes: [
                PathNode(file: file1, subnodes: [], loaded: true),
                PathNode(file: file2, subnodes: [], loaded: true)], loaded: true),
            PathNode(file: File(path: "/michael/smith", icon: .folder, isFolder: true), subnodes:
                        [PathNode(file: file4, subnodes: []),
                         PathNode(file: File(path: "/michael/smith/john", icon: .folder, isFolder: true), subnodes: [PathNode(file: file3, subnodes: [])])]),
            PathNode(file: file5, subnodes: [])], loaded: true)
        
    }
    var state: RepositoryViewState {
        get {
            let browserState = RepositoryFilesViewState(root: root)
            browserState.isLoading = false
            
            let editorState = EditorViewState(title: "fantasy-backend")
            let state = RepositoryViewState(
                editorState: editorState,
                browserState: browserState)
            state.editorState.openFiles = [
                File(path: "/michael/test.txt", content: "This is a test"),
                File(path: "/michael/go.txt", content: "This is a test"),
                File(path: "/michael/grew.txt", content: "This is a test"),
                File(path: "/michael/moalsdkjflaksdjflaksjdfl.txt", content: "This is a test"),
                File(path: "/michael/loasldfjalskdjflaksjlaksjdflkjasdlfkjaldflkasjdfw.txt", content: "This is a test")
            ]
            

            
            state.editorState.activeIndex = 2
            let fileEditorState = FileViewState()
            fileEditorState.isLoading = false
            fileEditorState.content = "This is a paragraph"
            state.editorState.activeFileState = fileEditorState
            return state
        }
    }
    
    return RepositoryView(state: state)
}

