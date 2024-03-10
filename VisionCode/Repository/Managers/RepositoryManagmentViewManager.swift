//
//  File.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/1/24.
//

import Foundation
import RealmSwift
import Combine

class RepositoryManagmentViewManager {
    let realm: Realm
    let hostManager: HostManager
    let projectManager: ProjectsManager
    let state: RepositoryManagmentViewState

    private var hostsObserver: AnyCancellable? = nil
    private var projectsObserver: AnyCancellable? = nil
    
    init(realm: Realm, connectionManager: ConnectionManager) {
        self.realm = realm
        self.hostManager = HostManager(realm: realm, connectionManager: connectionManager)
        self.projectManager = ProjectsManager(realm: realm)
        
        self.state = RepositoryManagmentViewState()
        self.state.onSelectHost = self.openHost
        self.state.onSelectProject = self.openProject
        
        self.hostsObserver = self.hostManager.hosts.sink { error in
            print("\(error)")
        } receiveValue: { [weak self] output in
            self?.state.hosts = output
        }
        self.projectsObserver = self.projectManager.projects.sink { error in
            print("\(error)")
        } receiveValue: { [weak self] output in
            self?.state.projects = output
        }
        
        self.hostManager.onCloseManagmentView = self.closeHostsView
        self.projectManager.onClosed = self.closeProject
    }
    
    func openHost(_ host: Host?) {
        state.projectsManagmentState = nil
        state.hostManagmentState = hostManager.open(host: host)
    }
    
    func closeHostsView() {
        // TODO: if I don't clear hosts, realm causes crash on deletion
        state.hosts = []
        
        state.hostManagmentState = nil
    }
    
    func openProject(_ project: Project?) {
        state.hostManagmentState = nil
        state.projectsManagmentState = projectManager.open(project, selectedHost: nil)
    }
    
    func closeProject(_ manager: ProjectsManager) {
        // TODO: if I don't clear hosts, realm causes crash on deletion
        state.projects = []
        
        state.projectsManagmentState = nil
    }
}
