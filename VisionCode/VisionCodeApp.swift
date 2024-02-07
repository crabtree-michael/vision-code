//
//  VisionCodeApp.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/18/24.
//

import SwiftUI
import VCRemoteCommandCore
import RealmSwift

@main
struct VisionCodeApp: SwiftUI.App {
    let realm:Realm
    let connectionManager = ConnectionManager()
    
    init() {
        realm = try! Realm()
    }
    
    var body: some Scene {
        WindowGroup(id: "editor", for: ObjectId.self) { input in
            let manager = RepositoryViewManager(realm: self.realm, 
                                                connectionManager: self.connectionManager,
                                                openProject: input.wrappedValue)
            RepositoryView(state: manager.state)
        }
        .defaultSize(CGSize(width: 1200, height: 700))
        .windowResizability(.contentSize)
    }
}
