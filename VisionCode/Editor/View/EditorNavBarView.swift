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
    @Binding var activeIndex: Int?
    var openFiles: [FileViewState]
    var title: String
    var onSelected: FileLambda? = nil
    var onClose: FileLambda? = nil
    var onQuickOpen: VoidLambda? = nil
    
    var body: some View {
        VStack(spacing: 2) {
            Button(action: {
                self.onQuickOpen?()
            }, label: {
                Label("Quick Open", systemImage: "sparkle.magnifyingglass")
            })
            .keyboardShortcut("p", modifiers: .command)
            .buttonStyle(QuickOpenButtonStyle())
            .padding()
            
            
            ScrollView(.horizontal) {
                HStack(spacing: 4) {
                    ForEach(Array(zip(openFiles.indices, openFiles)), id: \.0) { index, fvState in
                        if (index != self.activeIndex) {
                            EditorNavBarButton(state: fvState) {
                                self.onClose?(fvState.file)
                            }
                            .background(.ultraThinMaterial)
                            .hoverEffect()
                            .onTapGesture {
                                self.onSelected?(fvState.file)
                            }
                        } else {
                            EditorNavBarButton(state: fvState) {
                                self.onClose?(fvState.file)
                            }
                            .background(.black.opacity(0.46))
                        }
                    }
                    Spacer()
                }
            }
            .scrollPosition(id: $activeIndex)
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
    
    return EditorNavBar(activeIndex: .constant(0), openFiles: openFiles, title: "test")
}
