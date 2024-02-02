//
//  RepositoryViewState.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/1/24.
//

import Foundation

enum RepositoryViewTab {
    case managment
    case repository
}

class RepositoryViewState: ObservableObject {
    var managerState = RepositoryManagmentViewState()
    @Published var editorState: RepositoryEditorViewState?
    @Published var tabSelection: RepositoryViewTab = .managment
    
    var error: CommonError? = nil
}
