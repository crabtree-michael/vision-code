//
//  FileViewManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation
import VCRemoteCommandCore
import CodeEditLanguages
import Combine
import NIOCore

class FileViewManager {
    let path: String
    let state: FileViewState
    let file: File
    var client: RCSFTPClient?
    var hasAttemptedLoad: Bool = false
    let estimatedLanguage: CodeLanguage
    
    var onClose: FileLambda? = nil
    
    var onChannelClosed: VoidLambda? = nil
    
    private var originalContent: String? = nil
    private var tasks = [AnyCancellable]()
    private var didForceClose: Bool = false
    
    private var openHandle: Handle? = nil
    private var lastLoadedDate: Date? = nil
    
    init(path: String, client: RCSFTPClient?) {
        self.path = path
        self.file = File(path: path)
        self.state = FileViewState(file: self.file)
        self.client = client
        if let url = URL(string: self.path) {
            self.estimatedLanguage = CodeLanguage.detectLanguageFrom(url: url)
        } else {
            self.estimatedLanguage = .default
        }
        
        self.state.onSave = {
            self.save()
        }
        self.state.onSaveAndClose = self.saveAndClose
        self.state.onForceClose = self.forceClose
        self.state.onReloadRemote = self.load
        self.state.onOverwriteRemote = { [weak self] in
            self?.save(overrideModification: true)
        }
        self.state.language = self.estimatedLanguage
        
        self.state.$content.sink { _ in
        } receiveValue: { [weak self] content in
            self?.state.hasChanges = content != self?.originalContent
        }.store(in: &self.tasks)
    }
    
    func load() {
        guard let client = self.client else {
            print("I have no client!")
            return
        }
        
        self.hasAttemptedLoad = true
        Task {
            do {
                let handle = try await client.open(file: self.file.path, permissions: .READ)
                self.openHandle = handle
                
                let data = try await client.get(handle: handle)
                self.lastLoadedDate = Date()
                
                let content = String(decoding: data, as: UTF8.self)
                DispatchQueue.main.async {
                    self.originalContent = content
                    self.state.tabWidth = .estimate(from: content)
                    self.state.content = content
                    self.state.isLoading = false
                }
            } catch(let error) {
                handle(error: error)
            }
        }
    }
    
    func save(overrideModification: Bool = false, onCompletion: VoidLambda? = nil) {
        self.state.isWriting = true
        Task {
            guard let client = self.client else {
                return
            }
            do {
                guard let data = self.state.content.data(using: .utf8) else {
                    throw EditorError.encodingFailed
                }
                
                if let handler = self.openHandle,
                   let attr = try? await client.stat(handle: handler),
                   let mdate = attr.modifiedDate(),
                   let loadDate = self.lastLoadedDate,
                   mdate > loadDate && !overrideModification {
                    state.presentRemoteModifiedAlert = true
                    return
                }
                
                let writtenContent = self.state.content
                try await client.write(data, file: self.file.path)
                self.lastLoadedDate = Date()
                DispatchQueue.main.async {
                    self.originalContent = writtenContent
                    self.state.hasChanges = false
                    onCompletion?()
                }
            } catch(let error) {
                handle(error: error)
            }
            
            DispatchQueue.main.async {
                self.state.isWriting = false
            }
        }
    }
    
    private func handle(error: Error) {
        if let error = error as? EditorError {
            self.state.error = error
        } else {
            if let error = error as? ChannelError {
                switch(error) {
                case .ioOnClosedChannel, .alreadyClosed:
                    self.onChannelClosed?()
                default:
                    break
                }
            }
            self.state.error = .serverError(error)
        }
    }
    
    func saveAndClose() {
        self.save() {
            self.forceClose()
        }
    }
    
    func forceClose() {
        self.didForceClose = true
        self.onClose?(self.file)
    }
    
    func allowClosing() -> Bool {
        guard !self.didForceClose else {
            return true
        }
        
        guard state.hasChanges else {
            return true
        }
        
        self.state.presentUnsavedChangesAlert = true
        return false
    }
}
