//
//  FolderView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI

struct FolderView: View {
    @ObservedObject var state: FolderViewState
    
    var gridItems = [
        GridItem(.adaptive(minimum: 250)),
    ]

    var body: some View {
        VStack {
            VStack {
                FolderHeaderView(title: state.name, close: state.onClose)
                if self.state.isLoading {
                    Spacer()
                    ProgressView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: gridItems, alignment: .center, spacing: 45) {
                            ForEach(state.files ?? [], id: \.name) { file in
                                FileThumbnailView(file: file, action: state.onOpenFile)
                            }
                        }
                    }
                    .padding()
                }

            }
            Spacer()
        }
        .toolbar(content: {
            HStack {
                Text("Hello")
                Text("Test")
            }
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
