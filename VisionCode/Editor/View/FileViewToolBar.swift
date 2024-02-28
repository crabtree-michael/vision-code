//
//  FileToolBar.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/30/24.
//

import Foundation
import SwiftUI
import CodeEditLanguages


struct ToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .frame(minWidth: 36, maxHeight: 12)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .overlay(
                Rectangle()
                    .frame(width: 1, height: nil, alignment: .leading)
                    .foregroundColor(Color.gray), alignment: .leading
            )
            .hoverEffect(.highlight)
    }
}

struct FileViewToolBar: View {
    @ObservedObject var state: FileViewState
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            HStack(spacing: 0) {
                if !state.isWriting {
                    Button {
                        state.onSave?()
                    } label: {
                        Label(title: {
                            Text("Save")
                        }) {
                            Image(systemName: "network.badge.shield.half.filled")
                        }
                    }
                } else {
                    ProgressView()
                        .scaleEffect(CGSize(width: 0.7,
                                            height: 0.7))
                        .frame(minWidth: 36, maxHeight: 12)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .overlay(
                            Rectangle()
                                .frame(width: 1, height: nil, alignment: .leading)
                                .foregroundColor(Color.gray), alignment: .leading
                        )
                }
            
                Button {
                    state.showFindInFile = true
                } label: {
                    Label(title: {
                        Text("Find")
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
            
                Menu(state.language.tsName) {
                        Picker("Language", selection: $state.language) {
                            ForEach(CodeLanguage.allLanguages, id: \.id) { language in
                                Text(language.tsName)
                                    .tag(language)
                            }
                            
                        }
                    }
                }
                Menu(state.tabWidth.description) {
                    Picker(selection: $state.tabWidth, label: Label("Test", systemImage: "test")) {
                        ForEach(TabWidth.primarySet) { width in
                            Text(width.description)
                                .tag(width)
                            
                        }
                    }
                }
        }
        .menuStyle(.button)
        .buttonStyle(ToolbarButtonStyle())
        .frame(maxHeight: 32)
        .background(Color(Theme.current.backgroundColor))
    }
}

#Preview {
    var state: FileViewState {
        let state = FileViewState(file: .init(path: "test"))
        state.isWriting = true
        state.language = .c
        state.tabWidth = TabWidth(width: 2, spacing: .space)
        return state
    }
    
    @ObservedObject var s = state

    
    return FileViewToolBar(state: state)
}
