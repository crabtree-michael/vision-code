//
//  FinderView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI

struct FinderView: View {
    @ObservedObject var state: FinderViewState
    
    var body: some View {
        switch(state.connectionState) {
        case .connecting:
            Text("Connecting...")
            ProgressView()
        case .notStarted:
            ProgressView()
        case .failed(let error):
            Text("Failed to connect \(error.localizedDescription)")
        case .connected:
            ZStack {
                ForEach(state.openFolders, id: \.name) { folderState in
                    FolderView(state: folderState)
                        .background(.white.opacity(0.95))
                        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 10)))
                }
                .frame(depth: 50, alignment: .back)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

        }
    }
}
