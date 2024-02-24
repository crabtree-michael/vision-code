//
//  FileCellView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI

struct FileCellView: View {
    @ObservedObject var state: FileCellViewState
    
    let indentationLevel: Int
    let indentationWidth: CGFloat = 12
    
    var empty: Bool {
        return state.subnodes.isEmpty
    }
    
    @FocusState var isTextFocused: Bool
    @State var showInputBar: Bool = false
    @State var inputItem: FileIcon = .file
    
    @State var collapsed: Bool
   
    
    var onOpen: FileLambda?  = nil
    var onReloadDirectory: FileLambda? = nil
    var createFile: ((File, String) -> ())? = nil
    var createFolder: ((File, String) -> ())? = nil
    
    func onTap() {
        guard state.loaded else {
            return
        }
        guard !empty else {
            self.onOpen?(state.file)
            return
        }
        self.collapsed = !self.collapsed
        self.resetTextState()
    }
    
    func resetTextState() {
        self.showInputBar = false
        self.state.newFileName = ""
    }
    
    var menuItems: some View {
        Group {
            Button {
                self.onTap()
            } label: {
                if !empty && !collapsed {
                    Label("Close", systemImage: "eye.slash")
                } else {
                    Label("Open", systemImage: "eye")
                }
            }
            if state.file.isFolder {
                Button {
                    self.onReloadDirectory?(state.file)
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                Button {
                    self.showInputBar = true
                    self.collapsed = false
                    self.inputItem = .file
                } label: {
                    Label("New File", systemImage: "doc.badge.plus")
                }
                Button {
                    self.showInputBar = true
                    self.collapsed = false
                    self.inputItem = .folder
                } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
            }
        }
    }
    
    var body: some View {
        LazyVStack(spacing: 4) {
            ZStack {
                Color.black.opacity(0.0001)
                    .frame(minHeight: 48)
                HStack {
                    Color.black.opacity(0.0001)
                        .frame(maxWidth: indentationWidth * CGFloat(indentationLevel))
                    HStack(alignment: .center) {
                        if (!state.loaded) {
                            ProgressView()
                                .frame(maxHeight: 0)
                                .scaleEffect(CGSize(width: 0.4, height: 0.4))
                            
                        } else if (!empty) {
                            Image(systemName: !collapsed ? "chevron.down" : "chevron.right")
                        } else {
                            Image(systemName: state.file.icon.rawValue)
                        }
                        
                    }
                    .frame(maxWidth: 12)
                    Text(state.file.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                }
            }
            .onTapGesture {
                self.onTap()
            }
            .contextMenu(ContextMenu(menuItems: {
                menuItems
            }))
            if (self.showInputBar) {
                HStack {
                    Spacer(minLength: indentationWidth * CGFloat(indentationLevel + 1))
                    Image(systemName: inputItem.rawValue)
                    TextField("Filename",
                              text: $state.newFileName,
                              onEditingChanged: { editingChange in
                        if !editingChange {
                            self.resetTextState()
                        }
                    })
                    .onAppear(perform: {
                        self.isTextFocused = true
                    })
                    .onSubmit {
                        guard !state.newFileName.isEmpty else { return }
                        if inputItem == .file {
                            createFile?(state.file, state.newFileName)
                        } else {
                            createFolder?(state.file, state.newFileName)
                        }
                        self.resetTextState()
                    }
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused(self.$isTextFocused)
                }
                .background(Color(.darkGray.withAlphaComponent(0.8)))
                .padding(.trailing)
            }

            if (!empty && !collapsed && state.loaded) {
                ForEach(state.subnodes, id: \.file.path) { state in
                    FileCellView(state: state,
                                 indentationLevel: indentationLevel + 1,
                                 collapsed: true,
                                 onOpen: self.onOpen,
                                 onReloadDirectory: self.onReloadDirectory,
                                 createFile: self.createFile,
                                 createFolder: self.createFolder)
                }
            }
        }
        .hoverEffect()
    }
}

#Preview {
    var state: FileCellViewState {
        let root = PathNode(file: File(path: "test/"), 
                            subnodes:
                                [PathNode(file: File(path: "test/green.txt"), subnodes: []),
                                 PathNode(file: File(path: "test/green2.txt"), subnodes: []),
                                 PathNode(file: File(path: "test/blue.txt"), subnodes: [], loaded: true),
                                  PathNode(file: File(path: "test/blue2asdflajsdfaslkdf.txt"), subnodes: [], loaded: true)]
                            )
        root.loaded = true
        return FileCellViewState(node: root)
    }
    
    return FileCellView(state: state,
                 indentationLevel: 0,
                 collapsed: false,
                 onOpen: nil)
}
