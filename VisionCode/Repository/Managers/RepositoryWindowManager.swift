//
//  RepositoryWindowManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation
import VCRemoteCommandCore
import SwiftUI

class WindowManager {
    static let instance = WindowManager()
    var connection: RCConnection?  = nil
    
    @Environment(\.openWindow) private var openWindow
    
    private var managerMap: [String: RepositoryViewManager] = [:]
    
    func openEditor(file: String) {
        let path = (file as NSString).deletingLastPathComponent
        let manager = self.manager(forPath: path)
        manager.editor.open(path: file)
    }
    
    func manager(forPath path: String) -> RepositoryViewManager {
        var pathScan = "/"
        for component in (path as NSString).pathComponents {
            
            pathScan = (pathScan as NSString).appendingPathComponent(component)
            if let s = managerMap[pathScan] {
                return s
            }
        }
        return self.createAndOpenManager(forPath: path)
    }
    
    func createAndOpenManager(forPath path: String) -> RepositoryViewManager {
        let m = RepositoryViewManager(path: path, connection: self.connection!)
        self.managerMap[path] = m
        m.didClose = self.remove
        m.load()
        openWindow(id: "editor", value: path)
        return m
    }
    
    func remove(manager: RepositoryViewManager) {
        self.managerMap.removeValue(forKey: manager.path)
    }
}
