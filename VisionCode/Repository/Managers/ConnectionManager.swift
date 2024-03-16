//
//  ConnectionManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/2/24.
//

import Foundation
import VCRemoteCommandCore
import RealmSwift
import Combine

class ConnectionManager {
    private var connectionMap = [ObjectId: Connection]()
    private var queue = DispatchQueue(label: "connection-queue")
    private var realm: Realm?
    
    var cancellableSet = Set<AnyCancellable>()
    
    init() {
        self.realm = nil
        self.queue.async {
            self.realm = try! Realm(configuration: .defaultConfiguration, queue: self.queue)
        }
        
    }
    
    @MainActor func didDisconnect(for id: ObjectId, withResult result: Result<Void, Error>)  {
        guard let connection = connectionMap[id] else {
            return
        }
        
        switch (result) {
        case .success:
            connection.update(status: .notStarted)
        case .failure(let error):
            connection.update(status: .failed(error))
        }
    }
    
    @MainActor func reload(id: ObjectId) {
        guard let connection = self.connectionMap[id] else {
            return
        }
        
        self.load(connection: connection, for: id)
    }
    
    @MainActor func disconnect(id: ObjectId) {
        guard let connection = self.connectionMap[id] else {
            return
        }
        
        connection.close()
        connection.update(status: .notStarted)
    }
    
    @MainActor private func makeConnection(for id: ObjectId) -> Connection {
        let state = ConnectionViewState()
        state.onReload = { [weak self] in
            self?.reload(id: id)
        }
        state.disconnect = { [weak self] in
            self?.disconnect(id: id)
        }
    
        return Connection(connection: nil, state: state)
    }
    
    @MainActor private func load(connection: Connection, for id: ObjectId) {
        connection.update(status: .connecting)
        queue.async { [self] in
            guard let host = self.realm?.object(ofType: Host.self, forPrimaryKey: id) else {
                connection.update(status: .failed(CommonError.objectNotFound))
                return
            }
            
            let ip = host.ipAddress
            let port = host.port
            let username = host.username
            let password = host.password
            
            Task { [self] in
                do {
                    let c = RCConnection(host: ip, port: port, username: username, password: password)
                    try await c.connect { result in
                        Task {
                            await self.didDisconnect(for: id, withResult: result)
                        }
                    }
                    
                    connection.update(connection: c)
                    connection.update(status: .connected)
                }
                catch {
                    connection.update(status: .failed(error))
                }
            }
        }
    }
    
    @MainActor func connection(for id: ObjectId) -> Connection {
        if let connection = self.connectionMap[id] {
            if connection.state.status != .connecting || connection.state.status != .connected {
                self.load(connection: connection, for: id)
            }
            return connection
        }
        
        let connection = self.makeConnection(for: id)
        self.connectionMap[id] = connection
        self.load(connection: connection, for: id)
        return connection
    }
}
