//
//  FileToolBar.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/30/24.
//

import Foundation
import SwiftUI



struct FileViewToolBar: View {
    @ObservedObject var state: FileViewState
    
    var body: some View {
        HStack {
            Spacer()
            HStack {
                if !state.isWriting {
                    Text("Save")
                        .hoverEffect(.automatic)
                        .onTapGesture {
                            state.onSave?()
                        }
                } else {
                    ProgressView()
                        .scaleEffect(CGSize(width: 0.7,
                                            height: 0.7))
                }
            }
            .padding(EdgeInsets(top: 2,
                                leading: 10,
                                bottom: 2,
                                trailing: 10))
        }
        .frame(maxHeight: 26)
        .background(Color(.darkGray))
    }
}

#Preview {
    var state: FileViewState {
        let state = FileViewState()
        state.isWriting = true
        return state
    }
    
    return FileViewToolBar(state: state)
}
