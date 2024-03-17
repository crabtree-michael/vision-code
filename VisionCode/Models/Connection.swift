//
//  Connection.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/6/24.
//

import Foundation
import VCRemoteCommandCore

class Connection {
    private var connection: RCConnection?
    var state: ConnectionViewState
    
    var status: ConnectionState {
        return state.status
    }
    
    init(connection: RCConnection?, state: ConnectionViewState) {
        self.connection = connection
        self.state = state
    }
    
    func createSFTPClient() async throws -> RCSFTPClient {
        guard let connection = connection else {
            throw CommonError.notPrepared
        }
        
        return try await connection.createSFTPClient()
    }
    
    func createPTY(settings: RCPseudoTerminalSettings) async throws -> RCPseudoTerminal {
        guard let connection = connection else {
            throw CommonError.notPrepared
        }
        
        return try await connection.createTerminal(settings: settings)
    }
    
    func close() {
        connection?.close()
    }
    
    func update(connection: RCConnection?) {
        self.connection = connection
    }
    
    func update(status: ConnectionState) {
        DispatchQueue.main.async {
            self.state.status = status
        }   
    }
}
