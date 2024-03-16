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
    
    init(connection: Connection, directory: String) {
        self.state = TerminalViewState(connection: connection, directory: directory)
    }
}
