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
    var onSave: VoidLambda? = nil
    var isWriting: Bool = false
    @Binding var language: CodeLanguage
    
    var body: some View {
        HStack {
            Spacer()
            HStack {
                if !isWriting {
                    Button {
                        onSave?()
                    } label: {
                        Label(title: {
                            Text("Save")
                        }) {
                            Image(systemName: "network.badge.shield.half.filled")
                        }
                    }
                    .controlSize(.regular)
                    Picker("Language", selection: $language) {
                        ForEach(CodeLanguage.allLanguages, id: \.id) { language in
                            Text(language.tsName)
                                .tag(language)
                        }
                    }
                    
                } else {
                    ProgressView()
                        .scaleEffect(CGSize(width: 0.7,
                                            height: 0.7))
                }
            }
            .padding(EdgeInsets(top: 7,
                                leading: 10,
                                bottom: 7,
                                trailing: 10))
        }
        .frame(maxHeight: 52)
        .background(Color(.clear))
    }
}

#Preview {
    var state: FileViewState {
        let state = FileViewState()
        state.isWriting = true
        state.language = .c
        return state
    }
    
    @ObservedObject var s = state

    
    return FileViewToolBar(onSave: state.onSave, 
                           language: $s.language)
}
