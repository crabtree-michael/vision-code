//
//  FinderViewManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation
import VCRemoteCommandCore

class FinderViewManager {
    let state: FinderViewState
    let root: String
    
    private let connection: RCConnection
    private var client: RCSFTPClient? = nil
    
    private var rootManager: FinderFolderViewManager? = nil
    private var headManager: FinderFolderViewManager? = nil
    
    private var connectionState: ConnectionState = .notStarted {
        didSet {
            DispatchQueue.main.async {
                self.state.connectionState = self.connectionState
            }
        }
    }
    
    init(connection: RCConnection, root: String) {
        self.connection = connection
        self.root = root
        state = FinderViewState()
    }
    
    func connect() async {
        do {
            self.connectionState = .connecting
            self.client = try await self.connection.createSFTPClient()
            try self.createRootManager()
            try await self.rootManager?.load()
            self.connectionState = .connected
            self.setOpenFolders()
        } catch(let error) {
            self.connectionState = .failed(error)
        }
    }
    
    private func createRootManager() throws {
        guard let client = self.client else {
            throw CommonError.notPrepared
        }
        let root = FinderFolderViewManager(path: self.root,
                                        client: client,
                                        onNextManagerDidChange: self.managerDidChangeNextManager)
        self.rootManager = root
    }
    
    private func managerDidChangeNextManager(_ manager: FinderFolderViewManager) {
        self.setOpenFolders()
    }
    
    private func setOpenFolders() {
        var folders = [FolderViewState]()
        var head = self.rootManager
        while let node = head {
            folders.append(node.state)
            head = node.nextManager
        }
        DispatchQueue.main.async {
            self.state.openFolders = folders
        }
    }
}
