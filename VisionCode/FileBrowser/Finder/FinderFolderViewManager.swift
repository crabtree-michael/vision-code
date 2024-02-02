//
//  FinderFolderBrowserManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation
import VCRemoteCommandCore

class FinderFolderViewManager {
    let path: String
    let client: RCSFTPClient
    let state: FolderViewState
    var nextManager: FinderFolderViewManager?
    
    let onNextManagerDidChange: ((_ manager: FinderFolderViewManager) -> ())?
    
    var loading: Bool {
        didSet {
            DispatchQueue.main.async {
                self.state.isLoading = self.loading
            }
        }
    }
    
    var latestResponse: ListResponse? = nil {
        didSet {
            var files: [File] = []
            for file in latestResponse?.files ?? [] {
                if file.filename == "." || file.filename == ".." {
                    continue
                }
                files.append(File(self.path as NSString, sftpFile: file))
            }
            files = files.sorted { $0.name < $1.name }
            DispatchQueue.main.async {
                self.state.files = files
            }
        }
    }
    
    init(path: String, client: RCSFTPClient,
         nextManager: FinderFolderViewManager? = nil,
         onNextManagerDidChange: ((FinderFolderViewManager) -> ())? = nil,
         close: (() -> Void)? = nil) {
        self.path = path
        self.client = client
        self.state = FolderViewState(name: (path as NSString).lastPathComponent)
        self.nextManager = nextManager
        self.onNextManagerDidChange = onNextManagerDidChange
        self.loading = false
        self.state.onClose = close
        
        self.state.onOpenFile = self.openFile
    }
    
    func load() async throws {
        self.loading = true
        self.latestResponse = try await self.client.list(path: self.path)
        self.loading = false
    }
    
    func openFile(_ file: File) {
        guard !file.isFolder else {
            self.openFolder(file)
            return
        }

        print("File opening disabled")
    }
    
    func openFolder(_ folder: File) {
        let nextManager = FinderFolderViewManager(path: folder.path,
                                               client: self.client,
                                               onNextManagerDidChange: self.onNextManagerDidChange,
                                               close: self.closeChild)

        Task {
            do {
                try await nextManager.load()
            } catch (let error) {
                print("Failed to load \(error)")
            }
        }
        
        self.nextManager = nextManager
        self.onNextManagerDidChange?(self)
    }
    
    func closeChild() {
        self.nextManager = nil
        self.onNextManagerDidChange?(self)
    }
}
