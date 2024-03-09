//
//  Model.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/21/24.
//

import Foundation

enum ConnectionState: Equatable {
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
    
    static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
        switch(lhs, rhs) {
        case (.connected, .connected):
            return true
        case (.notStarted, .notStarted):
            return true
        case (.connecting, .connecting):
            return true
        case (.failed(_), .failed(_)):
            return true
        default:
            return false
        }
    }
}

enum CommandState {
    case unavailable
    case available
    case executing
}

class TerminalViewState: ObservableObject {
    let directory: String
    @Published var connection: Connection
    
    init(connection: Connection, directory: String) {
        self.connection = connection
        self.directory = directory
    }
}
