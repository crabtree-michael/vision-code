//
//  FinderViewState.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation

class FinderViewState: ObservableObject {
    @Published var connectionState: ConnectionState = .notStarted
    @Published var openFolders: [FolderViewState] = []
    var onOpenPath: ((String) -> ())? = nil
    var onClosePath: ((String) -> ())? = nil
    var onReturnHome: ((String) -> ())? = nil
}
