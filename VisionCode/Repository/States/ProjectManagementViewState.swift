//
//  ProjectManageViewState.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/1/24.
//

import Foundation
import RealmSwift
import SwiftUI

class ProjectManagementViewState: ObservableObject {
    var id:ObjectId?
    @Published var title: String
    @Published var hosts: [Host] = []
    @Published var selectedHost: Host?
    @Published var name: String
    @Published var rootPath: String
    @Published var canOpen: Bool = false
    @Published var isOpeningProject: Bool = false
    
    var onSave: ((ProjectManagementViewState) -> ())? = nil
    var onOpen: ((ProjectManagementViewState, OpenWindowAction) -> ())? = nil
    var onDelete: ((ProjectManagementViewState) -> ())? = nil
    
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
    }
}
