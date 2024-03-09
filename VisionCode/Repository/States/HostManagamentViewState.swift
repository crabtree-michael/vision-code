//
//  HostManagamentViewState.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/1/24.
//

import Foundation
import RealmSwift
import Combine

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
    @Published var hasChanges: Bool = false
    
    var textChangePublisher: AnyPublisher<HostManagamentViewState, Never> {
        return Publishers.CombineLatest(Publishers.CombineLatest4($name, $ipAddress, $port, $username), $password).map { _ in
            return self
        }
        .eraseToAnyPublisher()
    }
    
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
    
    func hasChangedFrom(host: Host?) -> Bool {
        return ipAddress != host?.ipAddress ?? "" ||
            name != host?.name ?? "" ||
            port != (host != nil ? "\(host?.port ?? 0)" : "") ||
            username != host?.username ?? "" ||
            password != host?.password ?? ""
    }
    
}
