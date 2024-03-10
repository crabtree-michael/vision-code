//
//  Errors.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation

enum CommonError: LocalizedError {
    case fileAlreadyExists
    case notPrepared
    case invalidPort
    case objectNotFound
    case unparsable
    case genericError(Error)
    
    var errorDescription: String? {
        switch(self) {
        case .fileAlreadyExists:
            return "File already exists"
        case .notPrepared:
            return "System is not prepared"
        case .invalidPort:
            return "Port is invalid"
        case .objectNotFound:
            return "Object not found"
        case .unparsable:
            return "Object could not be parsed"
        case .genericError(let error):
            return "Failed \(error.localizedDescription)"
        }
    }
}
