//
//  FolderHeaderView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI

struct FolderHeaderView: View {
    var title: String
    var close: (() -> ())?
    
    var body: some View {
        HStack {
            
            HStack {
                Button(action: {
                    
                }, label: {
                    Image(systemName: "house")
                })
                Button(action: {
                    self.close?()
                }, label: {
                    Image(systemName: "xmark.circle.fill")
                })
            }
            .padding()
            Spacer()
            Text(title)
                .foregroundStyle(.black)
                .font(.title)
                .padding()
            Spacer()
            Button(action: {
                
            }, label: {
                Image(systemName: "magnifyingglass")
            })
            .padding()
        }
    }
}

