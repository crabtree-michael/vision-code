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
    private var connectionMap = [ObjectId: RCConnection]()
    private var queue = DispatchQueue(label: "connection-queue")
    private var realm: Realm?
    
    init() {
        self.realm = nil
        self.queue.async {
            self.realm = try! Realm(configuration: .defaultConfiguration, queue: self.queue)
        }
        
    }
    
    func connection(for id: ObjectId) -> Future<RCConnection, Error> {
        return Future { [self] promise in
            queue.async { [self] in
                guard let host = self.realm?.object(ofType: Host.self, forPrimaryKey: id) else {
                    promise(.failure(CommonError.objectNotFound))
                    return
                }
                
                if let existingConnection = connectionMap[host.id] {
                    promise(.success(existingConnection))
                }
                
                let ip = host.ipAddress
                let port = host.port
                let username = host.username
                let password = host.password
                
                Task { [self] in
                    do {
                        let connection = RCConnection(host: ip, port: port, username: username, password: password)
                        try await connection.connect()
                        self.connectionMap[id] = connection
                        promise(.success(connection))
                    }
                    catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
}
