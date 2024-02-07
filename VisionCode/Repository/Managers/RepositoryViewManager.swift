//
//  RepositoryViewManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/2/24.
//

import Foundation
import RealmSwift
import VCRemoteCommandCore
import SwiftUI
import Combine

@MainActor
class RepositoryViewManager {
    let realm: Realm
    
    let managmentManager: RepositoryManagmentViewManager
    var editorManager: RepositoryEditorViewManager?
    let connectionManager: ConnectionManager

    let state = RepositoryViewState()
    
    var connectionCancellable: AnyCancellable? = nil
    
    var isOpeningProject: Bool = false {
        didSet {
            state.managerState.projectsManagmentState?.isOpeningProject = self.isOpeningProject
        }
    }
    
    @Environment(\.openWindow) private var openWindow
    
    init(realm: Realm,
         connectionManager: ConnectionManager,
         openProject: ObjectId? = nil) {
        self.realm = realm
        self.managmentManager = RepositoryManagmentViewManager(realm: realm)
        self.editorManager = nil
        self.connectionManager = connectionManager
        self.state.managerState = self.managmentManager.state
        self.managmentManager.projectManager.onOpened = self.open
        
        if let id = openProject,
           let project = realm.object(ofType: Project.self, forPrimaryKey: id) {
            self.open(project: project)
        }
    }
    
    func open(project: Project) {
        guard let hostID = project.host?.id else {
            print("Attempt to open project with no host")
            return
        }
        guard self.editorManager == nil else {
            openWindow(id: "editor", value: project.id)
            return
        }
        
        self.isOpeningProject = true
        self.connectionCancellable = self.connectionManager.connection(for: hostID).mapError({ error in
            return CommonError.genericError(error)
        }).sink(receiveCompletion: { completion in
            DispatchQueue.main.async {
                switch(completion) {
                case .failure(let error):
                    self.state.error = error
                case .finished: break
                }
                
                self.isOpeningProject = false
            }

        }, receiveValue: { connection in
            DispatchQueue.main.async {
                self.open(project: project, connection: connection)
            }
        })
    }
    
    private func open(project: Project, connection: Connection) {
        let manager = RepositoryEditorViewManager(path: project.root, connection: connection)
        if editorManager == nil {
            self.editorManager = manager
            manager.load()
            self.state.editorState = manager.state
            self.isOpeningProject = false
            self.state.tabSelection = .repository
        }
    }
    
}
