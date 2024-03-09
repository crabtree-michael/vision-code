//
//  HostManagmentView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/1/24.
//

import SwiftUI

struct HostManagamentView: View {
    @ObservedObject var state: HostManagamentViewState
    
    var isShowingError:Binding<Bool> {
        Binding {
            state.error != nil
        } set: { e in
            state.error = nil
        }
    }
    
    
    var body: some View {
        VStack
        {
            Form {
                Section("Code") {
                    HStack {
                        Text("Name")
                            .foregroundColor(.gray)
                        TextField("", text: $state.name)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                }
                Section("Connection") {
                    HStack {
                        Text("IP Address")
                            .foregroundColor(.gray)
                        TextField("", text: $state.ipAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    HStack {
                        Text("Port")
                            .foregroundColor(.gray)
                        TextField("", text: $state.port)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    HStack {
                        Text("Username")
                            .foregroundColor(.gray)
                        TextField("", text: $state.username)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    HStack {
                        Text("Password")
                            .foregroundColor(.gray)
                        SecureField("", text: $state.password)
                    }
                }
            }
            .toolbar {
                Button {
                    state.onSave?(state)
                } label: {
                    Label(
                        title: { Text("Save") },
                        icon: { Image(systemName: "pencil") }
                    )
                }
                .padding()
                Button {
                    state.onTestConnection?(state)
                } label: {
                    if state.attemptingConnection {
                        ProgressView()
                            .scaleEffect(CGSize(width: 0.6, height: 0.6))
                    } else {
                        Label(
                            title: { Text("Test connection") },
                            icon: {
                                if state.connectionSucceded {
                                    Image(systemName: "checkmark.seal")
                                } else {
                                    Image(systemName: "phone.connection.fill")
                                }
                                
                            }
                        )
                    }
                }
                if state.id != nil {
                    Button {
                        state.onDelete?(state)
                    } label: {
                        Label {
                            Text("Delete")
                        } icon: {
                            Image(systemName: "trash.fill")
                        }
                        
                    }
                }
            }
            if self.state.hasChanges {
                Button {
                    state.onSave?(state)
                } label: {
                    Label {
                        Text("Save")
                    } icon: {
                        Image(systemName: "pencil")
                    }
                }
            }
            Button {
                UIApplication.shared.open(sftpInstructionURL!)
            } label: {
                Text("How to enable SSH and SFTP on Mac OS")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.borderless)

        }
        .navigationTitle(state.title)
        .alert(isPresented: self.isShowingError, error: state.error) {
        }
    }
}

let sftpInstructionURL = URL(string: "https://support.apple.com/guide/mac-help/allow-a-remote-computer-to-access-your-mac-mchlp1066/mac")


#Preview {
    let state = HostManagamentViewState(host: nil)
    state.hasChanges = true
    return HostManagamentView(state: state)
}
