//
//  Model.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/21/24.
//

import Foundation

enum ConnectionState {
    case connected
    case notStarted
    case connecting
    case failed(Error)
}

enum CommandState {
    case unavailable
    case available
    case executing
}

class TerminalViewState: ObservableObject {
    @Published var connectionState: ConnectionState
    @Published var commandState: CommandState
    var title: String
    @Published var historyText: String
    var commandInputText: String
    var showTitle: Bool = true
    
    var onExecute: (() -> ())? = nil
    
    init(title: String = "", historyText: String = "",  commandInputText: String = "", connectionState: ConnectionState = .notStarted,
         commandState: CommandState = .available) {
        self.title = title
        self.historyText = historyText
        self.commandInputText = commandInputText
        self.connectionState = connectionState
        self.commandState = commandState
    }
    
    func enterCommandExecutingState() {
        self.commandInputText = ""
        self.commandState = .executing
        
    }
}
