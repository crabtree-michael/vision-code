//
//  TerminalManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/21/24.
//

import Foundation
import VCRemoteCommandCore

class TerminalManager {
    let state: TerminalViewState
    private let connection: Connection
    
    
    init(connection: Connection, directory: String) {
        self.connection = connection
        self.state = TerminalViewState(connection: connection, directory: directory)
    }
}
