//
//  ProjectManageViewState.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/1/24.
//

import Foundation
import RealmSwift
import SwiftUI
import Combine

class ProjectManagementViewState: ObservableObject {
    var id:ObjectId?
    @Published var title: String
    @Published var hosts: [Host] = []
    @Published var selectedHost: Host? {
        didSet {
            self.currentHostSubject.send(self.selectedHost)
        }
    }
    @Published var name: String
    @Published var rootPath: String
    @Published var canOpen: Bool = false
    @Published var hasChanges: Bool = false
    @Published var warnOfAbsolutePath: Bool = false
    
    var selectedHostPublisher: AnyPublisher<Host?, Never> {
        // This shouldn't be needed, but when I did the publisher on $selectedHost only
        // the old value was received
        return self.currentHostSubject.eraseToAnyPublisher()
    }
    
    var changePublisher: AnyPublisher<ProjectManagementViewState, Never> {
        return Publishers.CombineLatest3($name, $rootPath, selectedHostPublisher).map { _ in
            return self
        }
        .eraseToAnyPublisher()
    }
    
    var onSave: ((ProjectManagementViewState) -> ())? = nil
    var onOpen: ((ProjectManagementViewState, OpenWindowAction) -> ())? = nil
    var onDelete: ((ProjectManagementViewState) -> ())? = nil
    
    private var currentHostSubject = PassthroughSubject<Host?, Never>()
    
    init(project: Project?) {
        if let p = project {
            self.title = p.name
            self.name = p.name
            self.rootPath = p.root
            self.selectedHost = p.host
            self.id = p.id
        } else {
            self.title = "Add new project"
            self.name = ""
            self.rootPath = ""
            self.selectedHost = nil
            self.id = nil
        }
        
        self.currentHostSubject = PassthroughSubject()
        self.currentHostSubject.send(self.selectedHost)
    }
    
    func hasChanges(from project: Project?) -> Bool {
        return self.name != project?.name ?? "" ||
        self.rootPath != project?.root ?? "" ||
        self.selectedHost?.id != project?.host?.id
    }
}
