//
//  RepositoryView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI
import VCRemoteCommandCore

struct RepositoryEditorView: View {
    let cornerRadius: CGFloat = 6
    let minTerminalHeight: CGFloat = 150
    let minEditorHeight:CGFloat = 300
    let verticalControlSize: CGFloat = 15
    
    @ObservedObject var state: RepositoryEditorViewState
    @State var terminalHeight:CGFloat = 250
    
    @Environment(\.scenePhase) private var scenePhase
    
    var isShowingError:Binding<Bool> {
        Binding {
            state.error != nil
        } set: { _ in
            state.error = nil
        }
    }
    
    var verticalResizeDrag: some Gesture {
        DragGesture().onChanged { value in
            let newHeight = self.terminalHeight - value.translation.height
            self.terminalHeight = max(newHeight, minTerminalHeight)
        }
    }
    
    var body: some View {
        ZStack {
            if let browserState = state.browserState,
               let editorState = state.editorState,
               let terminalState = state.terminalState  {
                ZStack {
                    HStack(alignment: .top, spacing: 0) {
                        RepositoryFilesView(state: browserState)
                            .frame(width: 250)
                            .padding(.top)
                        
                            VStack(spacing: 0) {
                                Editor(state: editorState)
                                    .background(.ultraThickMaterial)
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
                                
                                TerminalView(state: terminalState)
                                    .frame(maxWidth: .infinity, maxHeight: terminalHeight)
                            }
            
                    }
                    .onDisappear {
                        self.state.onClose?()
                    }
                    if let qs = state.quickOpenSate {
                        Rectangle()
                            .opacity(0.001)
                            .onTapGesture {
                                state.closeQuickOpen?()
                            }
                        Spacer()
                        QuickOpenView(state: qs)
                            .frame(maxHeight: 500)
                            .background(.ultraThinMaterial)
                            .background(.white.opacity(0.9))
                            .clipShape(.rect(cornerSize: CGSize(width: 30, height: 30)))
                            .frame(depth: 60)
                            .padding(.horizontal, 100)
                            .padding(.bottom, 25)
                            .shadow(color: .black, radius: 25)
                    }
                }
                .frame(depth: 100, alignment: .back)
                
            } else {
                ProgressView()
            }
        }
        .alert(isPresented: isShowingError, content: {
            Alert(title: Text("Error with connection"),
                  message: Text(state.error?.localizedDescription ?? "Unknown"),
                  dismissButton: .default(Text("Ok"), action: {
                self.state.onDismissedError?()
            }))
        })
        .onChange(of: scenePhase) { _, newValue in
            state.scenePhase = newValue
        }
    }
}


@MainActor
struct ContentView_Previews: PreviewProvider {
    static var root: PathNode {
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
    static var connectionState: ConnectionViewState {
        let state = ConnectionViewState()
        state.status = .notStarted
        return state
    }
    static var state: RepositoryEditorViewState {
        get {
            let browserState = RepositoryFilesViewState(root: root, connectionState: connectionState)
            browserState.isLoading = false
            
            let editorState = EditorViewState(title: "fantasy-backend")
            let terminalState = TerminalViewState(connection:
                                                    Connection(connection: RCConnection(host: "", port: 0, username: "", password: ""),
                                                               state: ConnectionViewState()),
            directory: "test/")
            let state = RepositoryEditorViewState(
                connectionState: .connected, editorState: editorState,
                browserState: browserState,
                terminalState: terminalState)
            state.editorState?.openFiles = [
                File(path: "/michael/test.txt", content: "This is a test"),
                File(path: "/michael/go.txt", content: "This is a test"),
                File(path: "/michael/grew.txt", content: "This is a test"),
                File(path: "/michael/moalsdkjflaksdjflaksjdfl.txt", content: "This is a test"),
                File(path: "/michael/loasldfjalskdjflaksjlaksjdflkjasdlfkjaldflkasjdfw.txt", content: "This is a test")
            ]
            

            
            let fileEditorState = FileViewState(file: File(path: "test"))
            fileEditorState.isLoading = false
            fileEditorState.content = "This is a paragraph"
            state.editorState?.openFileStates = [fileEditorState]
            state.editorState?.activeIndex = 0
            return state
        }
    }
    
    static var previews: some View {
        Group {
            RepositoryEditorView(state: state)
        }
    }
}

