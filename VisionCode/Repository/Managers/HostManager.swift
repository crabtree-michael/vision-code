//
//  HostCreationManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/1/24.
//

import Foundation
import RealmSwift
import Combine
import VCRemoteCommandCore

class HostManager {
    let realm: Realm
    var currentState: HostManagamentViewState?
    
    var hosts: any Publisher<[Host], Error>
    
    var onCloseManagmentView: VoidLambda? = nil
    
    var latestHost: Host? = nil
    
    var tasks = Set<AnyCancellable>()
    
    let connectionManager: ConnectionManager
    
    init(realm: Realm, connectionManager: ConnectionManager) {
        self.realm = realm
        self.connectionManager = connectionManager
        self.currentState = nil
        
        self.hosts = realm.objects(Host.self).collectionPublisher
            .map { r in
                var hosts = [Host]()
                for host in r {
                    hosts.append(host)
                }
                return hosts
            }
    }
    
    func open(host: Host?) -> HostManagamentViewState {
        self.latestHost = host
        let state = HostManagamentViewState(host: host)
        currentState = state
        currentState?.onSave = self.save
        currentState?.onDelete = self.delete
        currentState?.onTestConnection = self.testConnection
        
        state.textChangePublisher.sink { [weak self] value in
            self?.currentState?.hasChanges = value.hasChangedFrom(host: self?.latestHost)
        }
        .store(in: &self.tasks)
        
        return state
    }
    
    func save(state: HostManagamentViewState) {
        guard let port = state.getPort() else {
            state.error = .invalidPort
            return
        }
        
        let host = Host()
        if let id = state.id {
            host.id = id
        }
        host.ipAddress = state.getIPAddress()
        host.name = state.getName()
        host.password = state.getPassword()
        host.port = port
        host.username = state.getUsername()
        
        do {
            try realm.write {
                realm.add(host, update: .modified)
            }
        } catch {
            state.error = .genericError(error)
        }
        
        state.title = host.name
        state.id = host.id
        
        self.latestHost = host
        currentState?.hasChanges = false 
        
        let id = host.id
        Task {
            await connectionManager.reload(id: id)
        }
    }
    
    func delete(state: HostManagamentViewState) {
        guard let id = state.id,
              let host = realm.object(ofType: Host.self, forPrimaryKey: id) else {
            return
        }
    
        do {
            try realm.write {
                realm.delete(host)
            }
        } catch {
            state.error = .genericError(error)
        }
        
        self.onCloseManagmentView?()
        self.currentState = nil
    }
    
    func testConnection(state: HostManagamentViewState) {
        guard let port = Int(state.port) else {
            state.error = .invalidPort
            return
        }
        
        state.attemptingConnection = true
        let connection = RCConnection(host: state.ipAddress, port: port, username: state.username, password: state.password)
        Task {
            var err: Error? = nil
            var success = true
            do {
                try await connection.connect()
                let _ = try await connection.createShell()
                connection.close()
            } catch {
                success = false
                err = error
            }
            
            let a = success
            let b = err
            DispatchQueue.main.async {
                state.attemptingConnection = false
                state.connectionSucceded = a
                if let err = b {
                    state.error = CommonError.genericError(err)
                }
               
            }
        }
    }
    
}
