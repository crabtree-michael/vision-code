//
//  VisionCodeApp.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/18/24.
//

import SwiftUI
import VCRemoteCommandCore

@main
struct VisionCodeApp: App {
    let host = Host()
    
    let browserManager: FinderViewManager
    
    init() {
        let connection = RCConnection(host: host.ipAddress, port: host.port, username: host.username, password: host.password)
        
        self.browserManager = FinderViewManager(connection: connection, root: "/Users/michael")
        WindowManager.instance.connection = connection
        
    
        let bManager = self.browserManager
        Task {
            do {
                try await connection.connect()
                await bManager.connect()
            } catch {
                print("Failed to make connection \(error)")
            }
        }
        
    }
    
    var body: some Scene {
        WindowGroup(id: "browser") {
            FinderView(state: self.browserManager.state)
        }
        .defaultSize(CGSize(width: 400, height: 250))
        .windowResizability(.contentMinSize)
        
        WindowGroup(id: "editor", for: String.self) { input in
            if let value = input.wrappedValue {
                let manager = WindowManager.instance.manager(forPath: value)
                RepositoryView(state: manager.state)
            }
            
        }
        .defaultSize(CGSize(width: 1200, height: 700))
        .windowResizability(.contentSize)
    }
}
