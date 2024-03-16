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
    var openHostId: ObjectId? = nil
    
    init(realm: Realm,
         connectionManager: ConnectionManager,
         openProject: ObjectId? = nil) {
        self.realm = realm
        self.managmentManager = RepositoryManagmentViewManager(realm: realm, connectionManager: connectionManager)
        self.editorManager = nil
        self.connectionManager = connectionManager
        self.state.managerState = self.managmentManager.state
        self.managmentManager.projectManager.onOpened = self.open
        
        if let id = openProject,
           let project = realm.object(ofType: Project.self, forPrimaryKey: id) {
            self.open(project: project)
        }
    }
    
    func open(project: Project, openWindow: OpenWindowAction? = nil) {
        guard let hostID = project.host?.id else {
            print("Attempt to open project with no host")
            return
        }
        guard self.editorManager == nil else {
            if let openWindow = openWindow {
                openWindow(id: "editor", value: project.id)
            }
            return
        }
        
        let manager = RepositoryEditorViewManager(path: project.root, connectionManager: connectionManager)
        if editorManager == nil {
            self.editorManager = manager
            manager.load(hostID: hostID)
            manager.onCloseEditor = {
                self.editorManager = nil
                self.state.editorState = nil
            }
            self.state.editorState = manager.state
            self.state.tabSelection = .repository
        }
        self.openHostId = project.host?.id
    }
}
