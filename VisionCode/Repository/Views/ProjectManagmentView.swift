//
//  ProjectManagmentView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/1/24.
//

import SwiftUI


struct ProjectManagmentView: View {
    @ObservedObject var state: ProjectManagementViewState
    @Environment(\.openWindow) var openWindow
    
    init(state: ProjectManagementViewState) {
        self.state = state
    }
    
    var body: some View {
        VStack {
            Form {
                Section {
                    HStack {
                        Text("Name")
                        TextField("", text: $state.name)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    if state.hosts.count > 0 {
                        Picker("Host", selection: $state.selectedHost) {
                            Text("Select").tag(nil as Host?)
                            ForEach(state.hosts, id: \.id) { host in
                                Text(host.name).tag(host as Host?)
                            }
                            .pickerStyle(.automatic)
                        }
                    } else {
                        Text("Add a host to continue")
                    }
                    HStack {
                        Text("Path")
                        TextField("Project root", text: $state.rootPath)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("Setttings")
                }
            }
            HStack {
                if (state.hasChanges) {
                    Button {
                        state.onSave?(state)
                    } label: {
                        Label("Save", systemImage: "pencil")
                    }
                }
                
                if (state.canOpen && !state.isOpeningProject) {
                    Button {
                        state.onOpen?(state, openWindow)
                    } label: {
                        Label(
                            title: { Text("Open") },
                            icon: { Image(systemName: "macwindow") }
                        )
                    }
                    .padding(.horizontal)
                } else if state.isOpeningProject {
                    ProgressView()
                        .padding(.horizontal)
                }
            }
            .padding()
        }
        .toolbar(content: {
            Button {
                state.onSave?(state)
            } label: {
                Label(
                    title: { Text("Save") },
                    icon: { Image(systemName: "pencil") }
                )
            }
            Button {
                state.onDelete?(state)
            } label: {
                Label(
                    title: { Text("Delete") },
                    icon: { Image(systemName: "trash.fill") }
                )
            }
        })
        .alert(isPresented: $state.warnOfAbsolutePath, content: {
            Alert(title: Text("Please use full path"),
                  message: Text("Do not use '~' or any other abbreviation."))
        })
        .navigationTitle(state.title)
    }
}


#Preview {
    func generateRandomHex() -> String {
        let hexDigits = Array("0123456789abcdef")
        var hexString = ""
        for _ in 0..<24 {
            hexString += String(hexDigits[Int.random(in: 0..<hexDigits.count)])
        }
        return hexString
    }
    
    var state: ProjectManagementViewState {
        
        let a = Host(name: "test")
        a.id = try! .init(string: generateRandomHex())

        let b = Host(name: "lose")
        b.id = try! .init(string: generateRandomHex())
        
        let state = ProjectManagementViewState(project: nil)
        state.hosts = [a, b]
        
        state.isOpeningProject = false
        state.canOpen = true
        state.hasChanges = true
        return state
    }
   
    return ProjectManagmentView(state:state)
}

