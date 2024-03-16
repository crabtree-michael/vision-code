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
    case contact
}

class RepositoryViewState: ObservableObject {
    var managerState = RepositoryManagmentViewState()
    @Published var editorState: RepositoryEditorViewState?
    @Published var tabSelection: RepositoryViewTab = .managment
    
    @Published var error: CommonError? = nil
    var onDisappear: VoidLambda? = nil
}
