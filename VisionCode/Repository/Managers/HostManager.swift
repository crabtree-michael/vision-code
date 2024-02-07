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
    
    init(realm: Realm) {
        self.realm = realm
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
        let state = HostManagamentViewState(host: host)
        currentState = state
        currentState?.onSave = self.save
        currentState?.onDelete = self.delete
        currentState?.onTestConnection = self.testConnection
        return state
    }
    
    func save(state: HostManagamentViewState) {
        let host = Host()
        if let id = state.id {
            host.id = id
        }
        host.ipAddress = state.ipAddress
        host.name = state.name
        host.password = state.password
        host.port = Int(state.port)!
        host.username = state.username
        
        do {
            try realm.write {
                realm.add(host, update: .modified)
            }
        } catch {
            state.error = .genericError(error)
        }
        
        state.title = host.name
        state.id = host.id
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
