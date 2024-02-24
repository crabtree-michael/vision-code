//
//  File 2.swift
//  
//
//  Created by Michael Crabtree on 1/23/24.
//

import Foundation
import NIOCore

struct SFTPMessageType: OptionSet {
    let rawValue: UInt8
    
    static let INIT = SFTPMessageType(rawValue: 1)
    static let VERSION = SFTPMessageType(rawValue: 2)
    static let OPEN = SFTPMessageType(rawValue: 3)
    static let CLOSE = SFTPMessageType(rawValue: 4)
    static let READ = SFTPMessageType(rawValue: 5)
    static let WRITE = SFTPMessageType(rawValue: 6)
    static let FSTAT = SFTPMessageType(rawValue: 8)
    static let OPENDIR = SFTPMessageType(rawValue: 11)
    static let READDIR = SFTPMessageType(rawValue: 12)
    static let MKDIR = SFTPMessageType(rawValue: 14)
    static let STATUS = SFTPMessageType(rawValue: 101)
    static let HANDLE = SFTPMessageType(rawValue: 102)
    static let DATA = SFTPMessageType(rawValue: 103)
    static let NAME = SFTPMessageType(rawValue: 104)
    static let ATTRS = SFTPMessageType(rawValue: 105)
}

struct SFTPStatusCode: OptionSet {
    let rawValue: UInt32
    
    static let OK = SFTPStatusCode([])
    static let EOF = SFTPStatusCode(rawValue: 1)
    static let NO_SUCH_FILE = SFTPStatusCode(rawValue: 2)
    static let PERMISSION_DENIED = SFTPStatusCode(rawValue: 3)
    static let FAILURE = SFTPStatusCode(rawValue: 4)
    static let BAD_MESSAGE = SFTPStatusCode(rawValue: 5)
    static let NO_CONNECTION = SFTPStatusCode(rawValue: 6)
    static let CONNECTION_LOST = SFTPStatusCode(rawValue: 7)
    static let OP_UNSUPPORTED = SFTPStatusCode(rawValue: 8)
}

public struct SFTPPermission: OptionSet {
    public let rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public static let READ   = SFTPPermission(rawValue: 0x00000001)
    public static let WRITE  = SFTPPermission(rawValue: 0x00000002)
    public static let APPEND = SFTPPermission(rawValue: 0x00000004)
    public static let CREAT  = SFTPPermission(rawValue: 0x00000008)
    public static let TRUNC  = SFTPPermission(rawValue: 0x00000010)
    public static let EXCL   = SFTPPermission(rawValue: 0x00000020)
}

class SFTPMessage {
    static var headerLength: UInt32 = 5
    
    let length: UInt32
    let type: SFTPMessageType
    var body: Data
    
    init(length: UInt32, type: SFTPMessageType, body: Data) {
        self.type = type
        self.length = length
        self.body = body
    }
    
    init(type: SFTPMessageType, body: Data) {
        self.type = type
        self.body = body
        self.length = UInt32(body.count + 1)
    }
    
    func buffer() -> ByteBuffer {
        var buffer = ByteBuffer()
        buffer.writeBytes(self.length.bigEdianBytes)
        buffer.writeBytes([self.type.rawValue])
        buffer.writeData(self.body)
        return buffer
    }
}

class SFTPVersionMessage: SFTPMessage {
    var version: UInt32!
    
    override init(length: UInt32, type: SFTPMessageType, body: Data) {
        self.version = .from(bytes: Array(body[0..<4].reversed()))
        super.init(length: length, type: type, body: body)
    }
}

class SFTPFullMessage: SFTPMessage {
    let requestID: UInt32
    override init(length: UInt32, type: SFTPMessageType, body: Data) {
        self.requestID = .from(bytes: Array(body[0..<4].reversed()))
        super.init(length: length, type: type, body: body)
    }
    
    init(buffer: inout ByteBuffer, length: UInt32, type: SFTPMessageType) throws {
        guard let b = buffer.readBytes(length: 4) else {
            throw SFTPError.malformedMessage
        }
        requestID = .from(bytes: b.reversed())
        super.init(length: length, type: type, body: Data())
    }
}

class SFTPStatusMessage: SFTPFullMessage {
    let code: SFTPStatusCode
    let message: String
    let tag: String
    
    override init(length: UInt32, type: SFTPMessageType, body: Data) {
        let bytes = Array(body)
        var read:UInt32 = 0
        self.code = SFTPStatusCode(rawValue: .from(bytes: bytes[4..<8].reversed()))
        (read, self.message) = String.from(paddedData: Array(bytes[8...]), encoding: UTF8.self)
        let tagStart = Int(read) + 8
        (read, self.tag) = String.from(paddedData: Array(bytes[tagStart...]), encoding: UTF8.self)
        super.init(length: length, type: type, body: body)
    }
}

class SFTPHandleMessage: SFTPFullMessage {
    let handle: String
    
    override init(length: UInt32, type: SFTPMessageType, body: Data) {
        (_, self.handle) = String.from(paddedData: Array(body[4...]), encoding: UTF8.self)
        super.init(length: length, type: type, body: body)
    }
}

class SFTPNameMessage: SFTPFullMessage {
    let count: UInt32
    let files: [File]

    
    override init(length: UInt32, type: SFTPMessageType, body: Data) {
        var location = 4
        self.count = .from(bytes: Array(body[location..<location + 4].reversed()))
        location += 4
        var files = [File]()
        for _ in 0..<Int(self.count) {
            let file = File(bytes: Array(body[location...]))
            files.append(file)
            location += file.byteSize
        }
        self.files = files
        super.init(length: length, type: type, body: body)
    }
}

class SFTPAttrMessage: SFTPFullMessage {
    var attr: FileAttributes! = nil
    
    init(buffer: inout ByteBuffer, length: UInt32) throws {
        try super.init(buffer: &buffer, length: length, type: .ATTRS)
        self.attr = try FileAttributes(buffer: &buffer)
    }
}

class SFTPDataMessage: SFTPFullMessage {
    var messageData: Data! = nil
    
    init(buffer: inout ByteBuffer, length: UInt32) throws {
        try super.init(buffer: &buffer, length: length, type: .READ)
        buffer.moveReaderIndex(forwardBy: 4) // Skip the length of the data
        guard let data = buffer.readData(length: buffer.readableBytes) else {
            throw SFTPError.malformedMessage
        }
        self.messageData = data
    }
}
