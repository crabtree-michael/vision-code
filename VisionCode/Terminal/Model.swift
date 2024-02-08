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
    
    func display() -> String {
        switch(self) {
        case .connected:
            return "Connected"
        case .notStarted:
            return "Not Started"
        case .connecting:
            return "Connecting"
        case .failed(_):
            return "Failure"
        }
    }
}

enum CommandState {
    case unavailable
    case available
    case executing
}

class TerminalViewState: ObservableObject {
    @Published var connection: Connection
    
    init(connection: Connection) {
        self.connection = connection
    }
}
