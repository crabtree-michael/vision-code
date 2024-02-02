//
//  RepositoryView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI



struct RepositoryEditorView: View {
    let cornerRadius: CGFloat = 6
    let minTerminalHeight: CGFloat = 150
    let minEditorHeight:CGFloat = 300
    let verticalControlSize: CGFloat = 15
    
    @ObservedObject var state: RepositoryEditorViewState
    @State var terminalHeight:CGFloat = 150
    
    var verticalResizeDrag: some Gesture {
        DragGesture().onChanged { value in
            let newHeight = self.terminalHeight - value.translation.height
            self.terminalHeight = max(newHeight, minTerminalHeight)
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            RepositoryFilesView(state: self.state.browserState)
                .frame(width: 200)
                .padding(.leading)
                .padding(.top)
                .padding(.bottom)

            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Editor(state: state.editorState)
                        .background(.ultraThickMaterial)
                        .frame(height: max(geometry.size.height - terminalHeight - verticalControlSize, minEditorHeight))
                        .cornerRadius(cornerRadius)
                        
                    ZStack {
                        Color(.systemBackground)
                        HStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.background)
                                .frame(maxWidth: 100, maxHeight: 9)
                                .gesture(verticalResizeDrag)
                                .hoverEffect()
                            Spacer()
                        }
                        
                    }
                    .frame(maxHeight: verticalControlSize)
                
                    TerminalView(state: state.terminalState)
                        .frame(maxWidth: .infinity, minHeight: min(terminalHeight, geometry.size.height - minEditorHeight - verticalControlSize))
                        .cornerRadius(cornerRadius)
                        
                }
                
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
    var state: RepositoryEditorViewState {
        get {
            let browserState = RepositoryFilesViewState(root: root)
            browserState.isLoading = false
            
            let editorState = EditorViewState(title: "fantasy-backend")
            let terminalState = TerminalViewState(title: "Hello")
            terminalState.connectionState = .connected
            terminalState.showTitle = false
            let state = RepositoryEditorViewState(
                editorState: editorState,
                browserState: browserState,
                terminalState: terminalState)
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
    
    return RepositoryEditorView(state: state)
}

