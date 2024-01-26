//
//  EditorNavBarView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI

struct EditorNavBar: View {
    @Binding var activeIndex: Int?
    var openFiles: [File]
    var title: String
    var onSelected: FileLambda? = nil
    var onClose: FileLambda? = nil
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.title)
                .frame(maxWidth: .infinity)
                
            ScrollView(.horizontal) {
                HStack(spacing: 4) {
                    ForEach(Array(openFiles.enumerated()), id: \.offset) { index, file in
                        if (index != self.activeIndex) {
                            EditorNavBarButton(name: file.name) {
                                self.onClose?(file)
                            }
                                .background(.ultraThinMaterial)
                                .hoverEffect()
                                .onTapGesture {
                                    self.onSelected?(file)
                                }
                        } else {
                            EditorNavBarButton(name: file.name) {
                                self.onClose?(file)
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

struct EditorNavBarButton: View {
    let name: String
    var closeAction: VoidLambda?
    
    var body: some View {
        HStack {
            Text(name)
                .lineLimit(1)
                .frame(alignment: .leading)
            Spacer(minLength: 25)
            Image(systemName: "xmark")
                .hoverEffect(.highlight)
                .clipShape(Circle())
                .onTapGesture {
                    closeAction?()
                }
        }
        .padding()
        .border(.background)
        .frame(maxWidth: 450)
    }
}
