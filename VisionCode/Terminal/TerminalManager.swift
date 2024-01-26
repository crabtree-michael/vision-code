//
//  TerminalManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/21/24.
//

import Foundation
import VCRemoteCommandCore

class TerminalManager {
    private let connection: RCConnection
    private var shell: RCShell?
    let state: TerminalViewState
    
    private var connectionState: ConnectionState = .notStarted {
        didSet {
            DispatchQueue.main.async {
                self.state.connectionState = self.connectionState
            }
        }
    }
    
    private var commandState: CommandState = .unavailable {
        didSet {
            DispatchQueue.main.async {
                self.state.commandState = self.commandState
            }
        }
    }
    
    
    init(title: String, connection: RCConnection) {
        self.connection = connection
        self.state = TerminalViewState(title: title,
                                   historyText: "",
                                   commandInputText: "")
        self.shell = nil
        
        self.state.onExecute = self.execute
    }
    
    func connect() async {
        do {
            self.connectionState = .connecting
            self.shell = try await self.connection.createShell()
            self.connectionState = .connected
            self.commandState = .available
        } catch (let error) {
            self.connectionState = .failed(error)
        }
    }
    
    func execute() {
        guard let shell = self.shell, self.commandState == .available else {
            return
        }
        
        let cmd = self.state.commandInputText
        guard cmd.count > 0 else {
            return
        }
        
        DispatchQueue.main.async {
            self.state.historyText.append("> " + cmd + "\n")
            self.state.enterCommandExecutingState()
        }
        
        Task {
            do {
                let result = try await shell.execute(cmd)
                DispatchQueue.main.async {
                    self.state.historyText.append(result.stdOut)
                    if (result.stdOut).count > 0 {
                        self.state.historyText.append("\n")
                    }
                    self.state.historyText.append(result.stdErr)
                    if ((result.stdErr + result.stdOut).count > 0) {
                        self.state.historyText.append("\n")
                    }
                    self.state.commandState = .available
                }
            } catch (let error) {
                print("Command failed \(error)")
            }
        }
    }
}
