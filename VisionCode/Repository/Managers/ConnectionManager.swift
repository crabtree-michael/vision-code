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
    
    func reloadIfNeeded(id: ObjectId) {
        guard let connection = self.connectionMap[id],
            connection.hasUsers() else {
            return
        }
        
        switch(connection.state.status) {
        case .failed(_), .notStarted:
            Task {
                await self.reload(id: id)
            }
        default:
            break
        }
    }
    
    @MainActor func didDisconnect(for id: ObjectId, withResult result: Result<Void, Error>)  {
        guard let connection = connectionMap[id] else {
            return
        }
        
        switch (result) {
        case .success:
            connection.state.status = .notStarted
        case .failure(let error):
            connection.state.status = .failed(error)
        }
    }
    
    @MainActor func reload(id: ObjectId) {
        guard let connection = self.connectionMap[id] else {
            return
        }
        
        connection.state.status = .connecting
        self.cancellableSet.insert(
            self.connection(for: id, reuse: false).sink { completion in
                switch (completion) {
                case .failure(let error):
                    Task {
                        await MainActor.run {
                            connection.state.status = .failed(CommonError.genericError(error))
                        }
                    }
                default: break
                }
            } receiveValue: { newConnection in
                newConnection.users = connection.users
                for user in connection.users {
                    user.connectionDidReload(newConnection)
                }
            }
        )
    }
    
    @MainActor func disconnect(id: ObjectId) {
        guard let connection = self.connectionMap[id] else {
            return
        }
        
        connection.connection.close()
        connection.state.status = .notStarted
    }
    
    @MainActor func connection(for id: ObjectId, reuse: Bool = true) -> Future<Connection, Error> {
        let state = ConnectionViewState()
        state.onReload = { [weak self] in
            self?.reload(id: id)
        }
        state.disconnect = { [weak self] in
            self?.disconnect(id: id)
        }
        state.status = .connecting
        return Future { [self] promise in
            queue.async { [self] in
                guard let host = self.realm?.object(ofType: Host.self, forPrimaryKey: id) else {
                    promise(.failure(CommonError.objectNotFound))
                    return
                }
                
                if let existingConnection = connectionMap[host.id], reuse {
                    promise(.success(existingConnection))
                }
                
                let ip = host.ipAddress
                let port = host.port
                let username = host.username
                let password = host.password
                
                Task { [self] in
                    do {
                        let connection = RCConnection(host: ip, port: port, username: username, password: password)
                        try await connection.connect { result in
                            Task {
                                await self.didDisconnect(for: id, withResult: result)
                            }
                        }
                        
                        state.status = .connected
                        let finalConnection = Connection(connection: connection, state: state)
                        self.connectionMap[id] = finalConnection
                        promise(.success(finalConnection))
                    }
                    catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
}
