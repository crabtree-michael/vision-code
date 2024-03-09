//
//  ConnectionState.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/6/24.
//

import Foundation

class ConnectionViewState: ObservableObject {
    @Published var status: ConnectionState = .notStarted
    var onReload: VoidLambda? = nil
    
    var disconnect: VoidLambda? = nil
    
    func displayMessage() -> String {
        switch(status) {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting"
        case .notStarted:
            return "Not Connected"
        case .failed(let error):
            return error.localizedDescription
        }
    }
    
    func actionIcon() -> String? {
        switch(status) {
        case .connected:
            return nil
        case .connecting:
            return nil
        case .notStarted:
            return "arrow.clockwise"
        case .failed(_):
            return "arrow.clockwise"
            
        }
    }
}
