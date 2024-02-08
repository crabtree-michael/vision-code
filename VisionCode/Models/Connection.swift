//
//  Connection.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/6/24.
//

import Foundation
import VCRemoteCommandCore

protocol ConnectionUser {
    func id() -> String
    func connectionDidReload(_ connection: Connection)
}

class Connection {
    var connection: RCConnection
    var state: ConnectionViewState
    var users: [ConnectionUser]
    
    init(connection: RCConnection, state: ConnectionViewState) {
        self.connection = connection
        self.state = state
        self.users = []
    }
    
    func createSFTPClient(user: ConnectionUser) async throws -> RCSFTPClient {
        if !self.users.contains(where: { $0.id() == user.id() }) {
            self.users.append(user)
        }
        return try await connection.createSFTPClient()
    }
    
    func createPTY(user: ConnectionUser, settings: RCPseudoTerminalSettings) async throws -> RCPseudoTerminal {
        if !self.users.contains(where: { $0.id() == user.id() }) {
            self.users.append(user)
        }
        
        return try await connection.createTerminal(settings: settings)
    }
}
