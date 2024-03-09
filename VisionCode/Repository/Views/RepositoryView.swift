//
//  RepositoryView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/1/24.
//

import SwiftUI


struct RepositoryView: View {
    @ObservedObject var state: RepositoryViewState
    
    @Environment(\.scenePhase) private var scenePhase
    
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
            ContactView()
            .tabItem {
                Label {
                    Text("About")
                } icon: {
                    Image(systemName: "person.fill")
                }
            }
            .tag(RepositoryViewTab.contact)
        }
        .alert(isPresented: isShowingError, error: state.error) {
            
        }
        .onDisappear {
            self.state.onDisappear?()
        }
        .onChange(of: scenePhase) { oldValue, newValue in
            if oldValue == .background && newValue == .active {
                self.state.didOpenFromBackground?()
            }
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

