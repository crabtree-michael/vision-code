//
//  ProjectsManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/1/24.
//

import Foundation
import RealmSwift
import Combine
import SwiftUI

class ProjectsManager {
    let realm: Realm
    
    let projects: any Publisher<[Project], Error>
    
    var onClosed: ((ProjectsManager) -> Void)? = nil
    var onOpened: ((Project, OpenWindowAction?) -> Void)? = nil
    
    var lastSavedProject: Project? = nil
    
    private var tasks = Set<AnyCancellable>()
    
    init(realm: Realm) {
        self.realm = realm
        self.projects = realm.objects(Project.self).collectionPublisher
            .map({ results in
                var projects = [Project]()
                for project in results {
                    projects.append(project)
                }
                return projects
            })
    }
    
    func open(_ project: Project?, selectedHost: Host?) -> ProjectManagementViewState {
        lastSavedProject = project
        let state = ProjectManagementViewState(project: project)
        if project == nil {
            state.selectedHost = selectedHost
        }
        
        var hosts = [Host]()
        let rHosts = realm.objects(Host.self)
        for host in rHosts {
            hosts.append(host)
        }
        state.hosts = hosts
        state.onSave = self.save
        state.onDelete = self.delete
        state.onOpen = self.open
        state.canOpen = project?.isValid() ?? false
        
        state.changePublisher.sink { [weak self] state in
            state.hasChanges = state.hasChanges(from: self?.lastSavedProject)
        }.store(in: &self.tasks)
        
        return state
    }
    
    func save(state: ProjectManagementViewState) {
        guard !state.rootPath.contains("~") else {
            state.warnOfAbsolutePath = true
            return
        }
        
        let project = self.project(for: state)
        do {
            try realm.write {
                realm.add(project, update: .modified)
            }
        } catch {
            print("\(error)")
        }
        
        state.id = project.id
        state.canOpen = project.isValid()
        state.title = project.name
        state.hasChanges = false
        
        self.lastSavedProject = project
    }
    
    func delete(state: ProjectManagementViewState) {
        guard let id = state.id, 
                let object = realm.object(ofType: Project.self, forPrimaryKey: id) else {
            return
        }
        
        do {
            try realm.write {
                realm.delete(object)
            }
        } catch {
            print("\(error)")
        }
        
        self.onClosed?(self)
    }
    
    func open(state: ProjectManagementViewState, action: OpenWindowAction) {
        guard !state.rootPath.contains("~") else {
            state.warnOfAbsolutePath = true
            return
        }
        
        let project = project(for: state)
        guard project.isValid() else {
            return
        }
        
        self.onOpened?(project, action)
    }
    
    private func project(for state: ProjectManagementViewState) -> Project {
        let project = Project()
        project.name = state.name
        project.root = state.rootPath
        project.host = state.selectedHost
        if let id = state.id {
            project.id = id
        }
        
        return project
        
    }
}
