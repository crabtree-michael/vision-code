//
//  FileToolBar.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/30/24.
//

import Foundation
import SwiftUI
import CodeEditLanguages

struct FileViewToolBar: View {
    @ObservedObject var state: FileViewState
    
    var body: some View {
        HStack {
            Spacer()
            HStack {
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
                .controlSize(.regular)
            } else {
                ProgressView()
                    .scaleEffect(CGSize(width: 0.7,
                                        height: 0.7))
                    .padding(EdgeInsets(top: 0,
                                        leading: 5,
                                        bottom: 0,
                                        trailing: 5))
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
            .controlSize(.regular)
                Picker("Language", selection: $state.language) {
                ForEach(CodeLanguage.allLanguages, id: \.id) { language in
                    Text(language.tsName)
                        .tag(language)
                }
            }
            }
            Picker("Tab width", selection: $state.tabWidth) {
                ForEach(TabWidth.primarySet) { width in
                    Text(width.description)
                        .tag(width)
                    
                }
            }
            .padding(.trailing)
        }
        .frame(maxHeight: 52)
        .background(Color(.clear))
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
