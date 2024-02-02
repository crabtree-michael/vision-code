//
//  RepositoryView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/1/24.
//

import SwiftUI


struct RepositoryView: View {
    @ObservedObject var state: RepositoryViewState
    
    var isShowingError:Binding<Bool> {
        Binding {
            state.error != nil
        } set: { e in
            state.error = nil
        }
    }
    
    var body: some View {
        TabView(selection: $state.tabSelection) {
            RepositoryManagerView(state: state.managerState)
            .tabItem {
                Label {
                    Text("Hosts")
                } icon: {
                    Image(systemName: "desktopcomputer")
                }
            }
            .tag(RepositoryViewTab.managment)
            if let state = state.editorState {
                RepositoryEditorView(state: state)
                .tabItem {
                    Label {
                        Text("Repository")
                    } icon: {
                        Image(systemName: "hammer.fill")
                    }
                }
                .tag(RepositoryViewTab.repository)
            }
        }
        .alert(isPresented: isShowingError, error: state.error) {
        }
    }
}

#Preview {
    var state: RepositoryViewState {
        let state = RepositoryViewState()
        return state
    }
   
    return RepositoryView(state:state)
}

