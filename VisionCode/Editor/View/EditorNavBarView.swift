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
    var openFiles: [File]
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
