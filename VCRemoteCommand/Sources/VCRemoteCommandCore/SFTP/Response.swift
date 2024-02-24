//
//  File 2.swift
//  
//
//  Created by Michael Crabtree on 1/23/24.
//

import Foundation
import NIOCore

class SFTPResponse {
    let id: UInt32
    let promise: EventLoopPromise<Void>

    required init(id: UInt32, promise: EventLoopPromise<Void>) {
        self.id = id
        self.promise = promise
    }
    
    func complete(with message: SFTPFullMessage) throws {
        throw SFTPError.unsupportedMessage
    }
}

class SFTPStatusResponse: SFTPResponse {
    override func complete(with message: SFTPFullMessage) throws {
        switch(message) {
        case let message as SFTPStatusMessage:
            guard message.code == .OK else {
                self.promise.fail(SFTPError.serverSuppliedError(message: message.message))
                return
            }
            
            self.promise.succeed()
        default:
            throw SFTPError.unsupportedMessage
        }
    }
}

class SFTPHandleResponse: SFTPResponse {
    internal var handle: String {
        return self.message?.handle ?? ""
    }
    
    private var message: SFTPHandleMessage?
    
    override func complete(with message: SFTPFullMessage) throws {
        
        switch(message) {
        case let message as SFTPHandleMessage:
            self.message = message
            self.promise.succeed()
        case let message as SFTPStatusMessage:
            self.promise.fail(SFTPError.serverSuppliedError(message: message.message))
        default:
            throw SFTPError.unsupportedMessage
        }
    }
}

class SFTPReadDirResponse: SFTPResponse {
    var loadedAllFiles: Bool = false
    
    internal var files: [File] {
       return self.message?.files ?? []
    }

    private var message: SFTPNameMessage?

    override func complete(with message: SFTPFullMessage) throws {
        switch(message) {
        case let message as SFTPNameMessage:
            self.message = message
            self.loadedAllFiles = false
            self.promise.succeed()
        case let message as SFTPStatusMessage:
            guard message.code == .EOF else {
                self.promise.fail(SFTPError.serverSuppliedError(message: message.message))
                return
            }
            self.loadedAllFiles = true
            self.promise.succeed()
        default:
            throw SFTPError.unsupportedMessage
       }
    }
}

class SFTPCloseResponse: SFTPResponse {
    override func complete(with message: SFTPFullMessage) throws {
        switch (message) {
        case let message as SFTPStatusMessage:
            if message.code == .OK || message.code == .EOF {
                self.promise.succeed()
                return
            }
            self.promise.fail(SFTPError.serverSuppliedError(message: message.message))
        default:
            throw SFTPError.unsupportedMessage
        }
    }
}

class SFTPStatResponse: SFTPResponse {
    var attributes: FileAttributes? = nil
    
    override func complete(with message: SFTPFullMessage) throws {
        switch(message) {
        case let message as SFTPStatusMessage:
            self.promise.fail(SFTPError.serverSuppliedError(message: message.message))
        case let message as SFTPAttrMessage:
            self.attributes = message.attr
            self.promise.succeed()
        default:
            throw SFTPError.unsupportedMessage
        }
    }
}

class SFTPReadResponse: SFTPResponse {
    var data: Data {
        get {
            message?.messageData ?? Data()
        }
    }
    var reachedEOF: Bool = false
    
    private var message: SFTPDataMessage?
    
    override func complete(with message: SFTPFullMessage) throws {
        switch (message) {
        case let message as SFTPDataMessage:
            self.message = message
            self.promise.succeed()
        case let message as SFTPStatusMessage:
            if message.code == .EOF {
                self.reachedEOF = true
                self.promise.succeed()
                return
            }

            self.promise.fail(SFTPError.serverSuppliedError(message: message.message))
        default:
            throw SFTPError.unsupportedMessage
        }
    }
}

class SFTPMkDirResponse: SFTPResponse {
    override func complete(with message: SFTPFullMessage) throws {
        switch (message) {
        case let message as SFTPStatusMessage:
            if message.code == .OK {
                self.promise.succeed()
                return
            }
            self.promise.fail(SFTPError.serverSuppliedError(message: message.message))
        default:
            throw SFTPError.unsupportedMessage
        }
    }
}
