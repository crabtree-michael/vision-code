//
//  RepositoryFilesView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI

struct IconOnlyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .labelStyle(.iconOnly)
            .padding()
            .hoverEffect()
    }
}


struct RepositoryFilesView: View {
    @ObservedObject var state: RepositoryFilesViewState
    
    var body: some View {
        ZStack {
            VStack {
                HStack(alignment: .center) {
                    Text(state.root.file.name)
                        .font(.title)
                    Spacer()
                    if (state.root.loaded) {
                        Button(action: {
                            self.state.refreshDirectory?(state.root.file)
                        }, label: {
                            Label(title: {
                                Text("Refresh")
                            }, icon: {
                                Image(systemName: "arrow.clockwise")
                            })
                        })
                        .buttonStyle(IconOnlyButtonStyle())
                    } else {
                        ProgressView()
                            .scaleEffect(
                                CGSize(width: 0.4, height: 0.4))
                    }
                }
                .padding([.top, .horizontal], 4)
                ScrollView {
                    LazyVStack(spacing: 4)
                    {
                        ForEach(state.root.subnodes, id: \.file.path) { state in
                            FileCellView(state: state,
                                         indentationLevel: 0,
                                         collapsed: true,
                                         onOpen: self.state.onOpenFile,
                                         onReloadDirectory: self.state.refreshDirectory)
                        }
                    }
                }
                Spacer(minLength: 46)
            }
            .padding(.bottom)
            .padding(.leading)
            switch(state.connectionState.status) {
            case .connected:
                VStack{
                    Spacer()
                    Button {
                        state.connectionState.disconnect?()
                    } label: {
                        Label(
                            title: { Text("Disconnect") },
                            icon: { Image(systemName: "icloud") }
                        )
                    }
                    
                }
                .padding()
            default:
                VStack {
                    Spacer()
                    HStack {
                        Text(state.connectionState.displayMessage())
                            .font(.caption)
                        Spacer()
                        switch(state.connectionState.status) {
                        case .connected: VStack{}
                        case .connecting:
                            ProgressView().scaleEffect(
                                CGSize(width: 0.5, height: 0.5))
                        case .failed(_), .notStarted:
                            Image(systemName: "arrow.clockwise")
                                .hoverEffect()
                                .onTapGesture {
                                    state.connectionState.onReload?()
                                }
                        }
                    }
                    .padding()
                    .background(.ultraThickMaterial)
                }
            }
        }
    }
}

@MainActor
struct RepositoryFilewsView_Previews: PreviewProvider {
    static var root: PathNode {
        let file1 = File(path: "/michael/george/test.txt", isFolder: false)
        let file2 = File(path: "/michael/george/long.txt", isFolder: false)
        let file3 = File(path: "/michael/smith/john/text.txt", isFolder: false)
        let file4 = File(path: "/michael/smith/text.txt", isFolder: false)
        let file5 = File(path: "/michael/test.txt", isFolder: false)
        
        return PathNode(file: File(path: "/michael"),
                        subnodes: [
                            PathNode(file: File(path: "/michael/george", icon: .folder, isFolder: true), subnodes: [
                                PathNode(file: file1, subnodes: [], loaded: true),
                                PathNode(file: file2, subnodes: [], loaded: true)], loaded: true),
                            PathNode(file: File(path: "/michael/smith", icon: .folder, isFolder: true), subnodes:
                                        [PathNode(file: file4, subnodes: []),
                                         PathNode(file: File(path: "/michael/smith/john", icon: .folder, isFolder: true), subnodes: [PathNode(file: file3, subnodes: [])])]),
                            PathNode(file: file5, subnodes: [])
                        ],
                        loaded: false)
    }
    
    static var connectionState: ConnectionViewState {
        let state = ConnectionViewState()
        state.status = .connected
        state.onReload = {
            state.status = .connecting
        }
        state.disconnect = {
            state.status = .notStarted
        }
        return state
    }
    
    static var state: RepositoryFilesViewState {
        get {
            let browserState = RepositoryFilesViewState(root: root, connectionState: connectionState)
            return browserState
        }
    }

    static var previews: some View {
        Group {
            RepositoryFilesView(state: state)
        }
    }
}
