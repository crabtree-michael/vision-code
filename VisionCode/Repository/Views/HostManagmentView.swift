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
                    }
                }
                Section("Connection") {
                    HStack {
                        Text("IP Address")
                            .foregroundColor(.gray)
                        TextField("", text: $state.ipAddress)
                    }
                    HStack {
                        Text("Port")
                            .foregroundColor(.gray)
                        TextField("", text: $state.port)
                    }
                    HStack {
                        Text("Username")
                            .foregroundColor(.gray)
                        TextField("", text: $state.username)
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
        }
        .navigationTitle(state.title)
        .alert(isPresented: self.isShowingError, error: state.error) {
        }
    }
}
