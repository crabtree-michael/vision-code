//
//  Model.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation

enum EditorError: LocalizedError {
    case serverError(Error)
    case encodingFailed
    case noHandler
    
    var errorDescription: String? {
        switch (self) {
        case .encodingFailed:
            return "Encoding failed"
        case .noHandler:
            return "Handler is closed"
        case .serverError(let error):
            return "Server error \(error)"
        }
    }
}
