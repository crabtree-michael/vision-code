//
//  RepositoryManagerView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/1/24.
//

import SwiftUI

struct RepositoryManagerView: View {
    @ObservedObject var state: RepositoryManagmentViewState
    
    var body: some View {
        NavigationSplitView {
            ScrollView {
                HStack {
                    VStack(alignment: .leading) {
                        
                        Text("Hosts")
                            .frame(alignment: .leading)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(state.hosts, id: \.name) { host in
                                Button {
                                    state.onSelectHost?(host)
                                } label: {
                                    Label(title: {
                                        Text(host.name)
                                    }) {
                                        Image(systemName: "network.badge.shield.half.filled")
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            Button(action: {
                                state.onSelectHost?(nil)
                            }, label: {
                                Label {
                                    Text("Add a host")
                                } icon: {
                                    Image(systemName: "plus")
                                }
                            })
                            .buttonStyle(.plain)
                        }
                        .padding(.leading)
                        
                        Text("Projects")
                            .frame(alignment: .leading)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(state.projects, id: \.id) { project in
                                Button(action: {
                                    state.onSelectProject?(project)
                                }, label: {
                                    Label {
                                        Text(project.name)
                                    } icon: {
                                        Image(systemName: "folder.badge.gearshape")
                                    }
                                })
                            }
                            .buttonStyle(.plain)
                            Button(action: {
                                state.onSelectProject?(nil)
                            }, label: {
                                Label {
                                    Text("Add a project")
                                } icon: {
                                    Image(systemName: "plus")
                                }
                            })
                            .buttonStyle(.plain)
                        }
                        .padding(.leading)
                    }
                    .padding(.leading)
                    Spacer()
                }
            }
            .frame(alignment: .leading)
            .navigationTitle("VisionCode")
        } detail: {
            if let managmentState = state.hostManagmentState {
                HostManagamentView(state: managmentState)
            }
            else if let projectsState = state.projectsManagmentState {
                ProjectManagmentView(state: projectsState)
            }
            else {
                Text("")
                    .font(.title3)
            }
  
            
        }
    }
}


#Preview {
    var state: RepositoryManagmentViewState {
        let state = RepositoryManagmentViewState()
        state.hosts = [Host(name: "Michael's iMac"), Host(name: "Work Computer")]
        state.projects = [Project()]
        state.projectsManagmentState = ProjectManagementViewState(project: nil)
        state.hostManagmentState?.attemptingConnection = true
        return state
    }
   
    return RepositoryManagerView(state:state)
}
