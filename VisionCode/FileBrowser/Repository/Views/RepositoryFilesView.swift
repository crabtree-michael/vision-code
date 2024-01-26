//
//  RepositoryFilesView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI

struct RepositoryFilesView: View {
    @ObservedObject var state: RepositoryFilesViewState
    
    var body: some View {
        VStack {
            Text("Explore")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.title2)
            ScrollView {
                FileCellView(state: state.root, indentationLevel: 0, collapsed: false, onOpen: state.onOpenFile)
            }
        }
        .frame(maxWidth: 200)
    }
}
