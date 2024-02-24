//
//  File 2.swift
//  
//
//  Created by Michael Crabtree on 1/23/24.
//

import Foundation
import NIOCore

class SFTPInitRequest: SFTPMessage {
    static let messageLength: UInt32 = 5
    let version: UInt32!
    init(version: UInt32) {
        self.version = version
        super.init(length: SFTPInitRequest.messageLength,
                   type: .INIT,
                   body: Data(version.bigEdianBytes))
    }
}

class SFTPFullRequest: SFTPMessage {
    let requestId: UInt32
    
    init(requestId: UInt32, type: SFTPMessageType, bytes: [UInt8]) {
        self.requestId = requestId
        var body = requestId.bigEdianBytes
        body.append(contentsOf: bytes)
        super.init(type: type, body: Data(body))
    }
}

class SFTPPathRequest: SFTPFullRequest {
    let path: String
    
    init(requestId: UInt32, type: SFTPMessageType, path: String) {
        self.path = path
        super.init(requestId: requestId,
                   type: type,
                   bytes: path.toUTF8PaddedString())
    }
}

class SFTPOpenDirRequest: SFTPPathRequest {
    init(requestId: UInt32, path: String) {
        super.init(requestId: requestId,
                   type: .OPENDIR,
                   path: path)
    }
}

class SFTPOpenFileRequest: SFTPFullRequest {
    let path: String
    let permissions: SFTPPermission
//    let flags: FileAttributes
    
    init(requestId: UInt32, path: String, permissions: SFTPPermission) {
        self.path = path
        self.permissions = permissions
        
        var buffer = ByteBuffer()
        buffer.writeBytes(path.toUTF8PaddedString())
        buffer.writeInteger(permissions.rawValue, endianness: .big)
        
        // TODO: Flag attribute is ignored
        buffer.writeInteger(UInt32(0), endianness: .big)
        
        super.init(requestId: requestId, type: .OPEN, bytes: buffer.readBytes(length: buffer.readableBytes)!)
    }
}

class SFTPHandleRequest: SFTPFullRequest {
    let handle: String
    
    init(requestId: UInt32, type: SFTPMessageType, handle: String) {
        self.handle = handle
        super.init(requestId: requestId,
                   type: type,
                   bytes: handle.toUTF8PaddedString())
    }
}

class SFTPReadDirRequest: SFTPHandleRequest {
    init(requestId: UInt32, handle: String) {
        super.init(requestId: requestId, 
                   type: .READDIR,
                   handle: handle)
    }
}

class SFTPCloseRequest: SFTPHandleRequest {
    init(requestId: UInt32, handle: String) {
        super.init(requestId: requestId, 
                   type: .CLOSE,
                   handle: handle)
    }
}

class SFTPFStatRequest: SFTPHandleRequest {
    init(requestId: UInt32, handle: String) {
        super.init(requestId: requestId,
                   type: .FSTAT,
                   handle: handle)
    }
}

class SFTPReadRequest: SFTPFullRequest {
    init(requestId: UInt32, handle: String, offset: UInt64, length: UInt32) {
        var buffer = ByteBuffer()
        buffer.writeBytes(handle.toUTF8PaddedString())
        buffer.writeInteger(offset, endianness: .big)
        buffer.writeInteger(length, endianness: .big)
        let data = buffer.readBytes(length: buffer.readableBytes)!
        super.init(requestId: requestId, type: .READ, bytes: data)
    }
}

class SFTPWriteRequest: SFTPFullRequest {
    init(requestId: UInt32, handle: String, data: Data, offset: UInt64) {
        var buffer = ByteBuffer()
        buffer.writeBytes(handle.toUTF8PaddedString())
        buffer.writeInteger(offset, endianness: .big)
        buffer.writeInteger(UInt32(data.count), endianness: .big)
        buffer.writeData(data)
        let data = buffer.readBytes(length: buffer.readableBytes)!
        super.init(requestId: requestId, type: .WRITE, bytes: data)
    }
}

class SFTPMkDirRequest: SFTPFullRequest {
    init(requestId: UInt32, path: String) {
        var buffer = ByteBuffer()
        buffer.writeBytes(path.toUTF8PaddedString())
        buffer.writeInteger(UInt32(0), endianness: .big) // Write 0 for file attributes
        let data = buffer.readBytes(length: buffer.readableBytes)!
        super.init(requestId: requestId, type: .MKDIR, bytes: data)
    }
}
