//
//  RepositoryManagerViewState.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/1/24.
//

import Foundation


class RepositoryManagmentViewState: ObservableObject {
    @Published var hosts: [Host] = []
    @Published var projects: [Project] = [] 
    @Published var hostManagmentState: HostManagamentViewState? = nil
    
    @Published var projectsManagmentState: ProjectManagementViewState? = nil
    
    var onSelectHost: ((Host?) -> Void)? = nil
    var onSelectProject: ((Project?) -> Void)? = nil
}
