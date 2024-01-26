//
//  FileViewManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation
import VCRemoteCommandCore

class FileViewManager {
    let path: String
    let state: FileViewState
    let file: File
    var client: RCSFTPClient?
    var hasAttemptedLoad: Bool = false
    
    init(path: String, client: RCSFTPClient?) {
        self.path = path
        self.state = FileViewState()
        self.file = File(path: path)
        self.client = client
        self.state.onSave = self.save
    }
    
    func load() {
        guard let client = self.client else {
            print("I have no client!")
            return
        }
        
        self.hasAttemptedLoad = true
        Task {
            do {
                let data = try await client.get(file: self.file.path)
                let content = String(decoding: data, as: UTF8.self)
                DispatchQueue.main.async {
                    self.state.content = content
                    self.state.isLoading = false
                }
            } catch(let error) {
                self.state.error = .serverError(error)
            }
        }
    }
    
    func save() {
        self.state.isWriting = true
        Task {
            guard let client = self.client else {
                return
            }
            do {
                guard let data = self.state.content.data(using: .utf8) else {
                    throw EditorError.encodingFailed
                }
                
                try await client.write(data, file: self.file.path)
            } catch(let error) {
                if let error = error as? EditorError {
                    self.state.error = error
                } else {
                    self.state.error = .serverError(error)
                }
            }
            
            DispatchQueue.main.async {
                self.state.isWriting = false
            }
        }
    }
}
