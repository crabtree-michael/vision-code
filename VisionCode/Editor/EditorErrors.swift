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
    
    var errorDescription: String? {
        switch (self) {
        case .encodingFailed:
            return "Encoding failed"
        case .serverError(let error):
            return "Server error \(error)"
        }
    }
}
