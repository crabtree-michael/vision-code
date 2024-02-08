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
    var onQuickOpen: VoidLambda? = nil
    
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Image(systemName: "sparkle.magnifyingglass")
                Text("Quick Open")
                    .foregroundStyle(.primary)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, minHeight: 35)
            .background(Color.gray.opacity(0.25))
            .clipShape(.rect(cornerSize: CGSize(width: 10, height: 10)))
            .padding(.top)
            .padding(.horizontal)
            .hoverEffect(.lift)
            .onTapGesture {
                self.onQuickOpen?()
            }
            
            Text(title)
                .font(.largeTitle)
                .padding(.vertical, 4)
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
                .onTapGesture {
                    closeAction?()
                }
        }
        .padding(.top)
        .padding(.horizontal)
        .padding(.bottom, 4)
        .border(.background)
        .frame(maxWidth: 450)
    }
}

#Preview {
    EditorNavBar(activeIndex: .constant(0), openFiles: [
        File(path: "test.txt"),
        File(path: "go.txt"),
        File(path: "john.txt")
    ], title: "test")
}
