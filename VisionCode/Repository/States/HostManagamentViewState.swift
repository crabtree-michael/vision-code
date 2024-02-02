//
//  HostManagamentViewState.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/1/24.
//

import Foundation
import RealmSwift

typealias HostManagamentViewStateLambda = (HostManagamentViewState) -> Void

class HostManagamentViewState: ObservableObject {
    @Published var id: ObjectId?
    @Published var title: String
    @Published var name: String
    @Published var ipAddress: String
    @Published var port: String
    @Published var username: String
    @Published var password: String
    @Published var error: CommonError? = nil
    
    var onSave: HostManagamentViewStateLambda? = nil
    var onDelete: HostManagamentViewStateLambda? = nil
    var onTestConnection: HostManagamentViewStateLambda? = nil
    
    @Published var attemptingConnection: Bool = false
    @Published var connectionSucceded: Bool = false
    
    init(host: Host?) {
        if let host = host {
            id = host.id
            name = host.name
            ipAddress = host.ipAddress
            port = "\(host.port)"
            username = host.username
            password = host.password
            title = host.name
        } else {
            id = nil
            title = "New Connection"
            name = ""
            ipAddress = ""
            port = ""
            username = ""
            password = ""
        }
    }
    
}
