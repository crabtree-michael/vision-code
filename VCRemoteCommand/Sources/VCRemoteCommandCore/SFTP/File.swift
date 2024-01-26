//
//  File.swift
//  
//
//  Created by Michael Crabtree on 1/23/24.
//

import Foundation

struct FileAttrFlag: OptionSet {
    let rawValue: UInt32

    static let SIZE        =  FileAttrFlag(rawValue: 0x00000001)
    static let UIDGID      =  FileAttrFlag(rawValue: 0x00000002)
    static let PERMISSIONS =  FileAttrFlag(rawValue: 0x00000004)
    static let ACMODTIME   =  FileAttrFlag(rawValue: 0x00000008)
    static let EXTENDED    =  FileAttrFlag(rawValue: 0x80000000)
}


public struct FileAttributes {
    internal let byteSize: Int
    let flag: FileAttrFlag
    public let size: UInt64?
    public let uid: UInt32?
    public let gid: UInt32?
    public let permissions: UInt32?
    public let atime: UInt32?
    public let mtime: UInt32?
    let extended_count: UInt32?

    init(bytes: [UInt8]) {
        self.flag = FileAttrFlag(rawValue: .from(bytes: bytes[0..<4].reversed()))
        var x = 4
        if self.flag.contains(.SIZE) {
            self.size = UInt64.from(bytes: bytes[x..<x+8].reversed())
            x += 8
        } else {
            self.size = nil
        }
        if self.flag.contains(.UIDGID) {
            self.uid = .from(bytes: bytes[x..<x+4].reversed())
            self.gid = .from(bytes: bytes[x+4..<x+8].reversed())
            x += 8
        } else {
            self.uid = nil
            self.gid = nil
        }
        if self.flag.contains(.PERMISSIONS) {
            self.permissions = .from(bytes: bytes[x..<x+4].reversed())
            x += 4
        } else {
            self.permissions = nil
        }
        if self.flag.contains(.ACMODTIME) {
            self.atime = .from(bytes: bytes[x..<x+4].reversed())
            self.mtime = .from(bytes: bytes[x+4..<x+8].reversed())
            x += 8
        } else {
            self.atime = nil
            self.mtime = nil
        }
        if self.flag.contains(.EXTENDED) {
            self.extended_count = .from(bytes: bytes[x..<x+4].reversed())
            x += 4
            for _ in 0..<Int(self.extended_count ?? 0) {
                let (read, first) = String.from(paddedData: Array(bytes[x...]), encoding: UTF8.self)
                x += Int(read)
                let (read2, second) = String.from(paddedData: Array(bytes[x...]), encoding: UTF8.self)
                x += Int(read2)
            }
        } else {
            self.extended_count = nil
        }

        self.byteSize = x
    }
}

public struct File {
    internal let byteSize:Int
    
    public var isDirectory: Bool {
        get {
            return longName.first == "d"
        }
    }
    
    public let filename: String
    public let longName: String
    public let attributes: FileAttributes

    internal init(bytes: [UInt8]) {
        var x = 0
        var read:UInt32 = 0
        (read, self.filename) = String.from(paddedData: Array(bytes[x...]), encoding: UTF8.self)
        x += Int(read)
        (read, self.longName) = String.from(paddedData: Array(bytes[x...]), encoding: UTF8.self)
        x += Int(read)
        self.attributes = FileAttributes(bytes: Array(bytes[x...]))
        x += self.attributes.byteSize
        self.byteSize = x
    }
}
