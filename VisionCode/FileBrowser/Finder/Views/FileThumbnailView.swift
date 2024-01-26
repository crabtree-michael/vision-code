//
//  FileThumbnailView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI

struct FileThumbnailView: View {
    var file: File
    var action: ((File) -> ())?
    
    var body: some View {
        VStack {
            Image(systemName: file.icon.rawValue)
                .resizable()
                .foregroundColor(.blue)
                .frame(width: 75, height: 75)
            Text(file.name)
                .foregroundStyle(.black)
                .font(.title2)
        }
        .hoverEffect(.highlight)
        .onTapGesture {
            self.action?(self.file)
        }
    }
}

