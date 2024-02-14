//
//  EditorNavBarView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI

struct QuickOpenButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 35)
            .background(Color.gray.opacity(0.25))
            .hoverEffect()
            .clipShape(.rect(cornerSize: CGSize(width: 10, height: 10)))
    }
}

struct EditorNavBar: View {
    @ObservedObject var state: EditorViewState
    
    var body: some View {
        ZStack {
            Button {
                if let index = state.activeIndex,
                   index >= 1 {
                    state.onFileSelected?(state.openFiles[index - 1])
                }
            } label: {
                Label("Move tab left", systemImage: "test")
            }
            .opacity(0.0001)
            .keyboardShortcut("{", modifiers: [.command, .shift])
            
            Button {
                if let index = state.activeIndex,
                   index < self.state.openFiles.count - 1 {
                    state.onFileSelected?(state.openFiles[index + 1])
                }
            } label: {
                Label("Move tab right", systemImage: "test")
            }
            .opacity(0.0001)
            .keyboardShortcut("}", modifiers: [.command, .shift])
            
            Button {
                if let index = state.activeIndex {
                    self.state.onFileClose?(self.state.openFiles[index])
                }
            } label: {
                Label("Close tab", systemImage: "test")
            }
            .opacity(0.0001)
            .keyboardShortcut("w", modifiers: .command)
            
            VStack(spacing: 2) {
                Button(action: {
                    self.state.onQuickOpen?()
                }, label: {
                    Label("Quick Open", systemImage: "sparkle.magnifyingglass")
                })
                .keyboardShortcut("p", modifiers: .command)
                .buttonStyle(QuickOpenButtonStyle())
                .padding()
                
                ScrollView(.horizontal) {
                    HStack(spacing: 4) {
                        ForEach(Array(zip(state.openFileStates.indices, state.openFileStates)),
                                id: \.0) { arrayIndex, fileState in
  
                            if (arrayIndex != state.activeIndex) {
                                EditorNavBarButton(state: fileState) {
                                    self.state.onFileClose?(fileState.file)
                                }
                                .background(.ultraThinMaterial)
                                .hoverEffect()
                                .onTapGesture {
                                    self.state.onFileSelected?(fileState.file)
                                }
                            } else {
                                EditorNavBarButton(state: fileState) {
                                    self.state.onFileClose?(fileState.file)
                                }
                                .background(.black.opacity(0.46))
                            }
                            
                        }
                        Spacer()
                    }
                }
                .scrollPosition(id: $state.activeIndex)
            }
        }
    }
}

struct EditorNavBarCloseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Color.gray
                .opacity(0.0001)
                .frame(width: 30, height: 30)
            Image(systemName: (configuration.role == .none && !configuration.isPressed) ? "circle.inset.filled" : "xmark")
                .background(Color.clear)
        }
        .hoverEffect()
    }
}

struct EditorNavBarButton: View {
    @ObservedObject var state: FileViewState
    var closeAction: VoidLambda?
    
    @State private var isHoveringOnCancel: Bool = false
    
    var body: some View {
        HStack {
            Text(state.name)
                .lineLimit(1)
                .frame(alignment: .leading)
            Spacer(minLength: 25)
            Button(role: state.hasChanges ? .none : .destructive) {
                closeAction?()
            } label: {
                Text("ignored")
            }
            .buttonStyle(EditorNavBarCloseButtonStyle())
        }
        .padding(.vertical, 4)
        .padding(.leading)
        .padding(.trailing, 6)
        .border(.background)
        .frame(maxWidth: 450)
    }
}

#Preview {
    var openFiles: [FileViewState] {
        get {
            let changed = FileViewState(file: File(path: "test.txt"))
            changed.hasChanges = true
            return [
                changed,
                FileViewState(file: File(path: "go.txt")),
                FileViewState(file: File(path: "john.txt"))
            ]
        }
    }
    
    var state: EditorViewState {
        let state = EditorViewState(title: "test")
        state.openFileStates = openFiles
        return state
    }
    
    return EditorNavBar(state: state)
}
