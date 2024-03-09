//
//  RepositoryFilesViewState.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI
import Combine

class RepositoryFilesViewState: ObservableObject {
    @Published var root: FileCellViewState
    @Published var isLoading: Bool = true
    @Published var connectionState: ConnectionViewState {
        didSet {
            connectionState.$status.sink { status in
                self.manualUpdate += 1
            }.store(in: &subscriptions)
        }
    }
    
    @Published var manualUpdate: Int = 0
    @Published var showLargeFolderWarning: Bool = false
    
   var subscriptions: [AnyCancellable]
    
    @Published var error: Error? = nil
    
    var onOpenFile: FileLambda? = nil
    var refreshDirectory: FileLambda? = nil
    var createFile: ((File, String) -> ())? = nil
    var createFolder: ((File, String) -> ())? = nil
    var loadLargeFolder: VoidLambda? = nil
    
    init(root: PathNode, connectionState: ConnectionViewState) {
        self.root = FileCellViewState(node: root)
        self.connectionState = connectionState
        subscriptions = []
        
        connectionState.$status.sink { status in
            self.manualUpdate += 1
        }.store(in: &subscriptions)
    }
}
