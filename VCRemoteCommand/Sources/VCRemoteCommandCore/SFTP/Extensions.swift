//
//  File 2.swift
//  
//
//  Created by Michael Crabtree on 1/23/24.
//

import Foundation
import NIOCore

extension UInt32 {
    var bigEdianBytes: [UInt8] {
        var bigEndian = self.bigEndian
        let count = MemoryLayout<UInt32>.size
        let bytePtr = withUnsafePointer(to: &bigEndian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        return Array(bytePtr)
    }
    
    static func from(bytes: [UInt8]) -> UInt32 {
        guard bytes.count == 4 else {
            preconditionFailure("UInt32 is comprised of only 4 bytes, got \(bytes.count)")
        }
        
        return   (UInt32(bytes[0]) << (0*8)) | // shifted by zero bits (not shifted)
        (UInt32(bytes[1]) << (1*8)) | // shifted by 8 bits
        (UInt32(bytes[2]) << (2*8)) | // shifted by 16 bits
        (UInt32(bytes[3]) << (3*8))   // shifted by 24 bits
    }
}

extension UInt64 {
    static func from(bytes: [UInt8]) -> UInt64 {
        guard bytes.count == 8 else {
            preconditionFailure("UInt64 is comprised of only 8 bytes, got \(bytes.count)")
        }
        
        return   (UInt64(bytes[0]) << (0*8)) | // shifted by zero bits (not shifted)
        (UInt64(bytes[1]) << (1*8)) | // shifted by 8 bits
        (UInt64(bytes[2]) << (2*8)) | // shifted by 16 bits
        (UInt64(bytes[3]) << (3*8)) | // shifted by 24 bits
        (UInt64(bytes[4]) << (4*8)) | // shifted by 32 bits
        (UInt64(bytes[5]) << (5*8)) | // shifted by 40 bits
        (UInt64(bytes[6]) << (6*8)) | // shifted by 48 bits
        (UInt64(bytes[7]) << (7*8))   // shifted by 56 bits
    }
}

extension Int {
    static let maxUInt32 = Int(UInt32.max)
}

extension String {
    public static func from(buffer: inout ByteBuffer) throws -> String {
        var bytes = try buffer.readOrThrow(length: 4)
        let length = UInt32.from(bytes: bytes.reversed())
        if length == 0 {
            return ""
        }
        
        bytes = try buffer.readOrThrow(length: Int(length))
        let result = String(decoding: bytes, as: UTF8.self)
        return result
    }
    
    public static func from<Encoding>(paddedData data: [UInt8], encoding: Encoding.Type) -> (UInt32, String) where Encoding : _UnicodeEncoding, Encoding.CodeUnit == UInt8  {
        guard data.count >= 4 else {
            preconditionFailure("padded data does not begin with string length")
        }
        
        let length = UInt32.from(bytes: data[0..<4].reversed())
        if length == 0 {
            return (4, "")
        }
        
        let result = String(decoding: data[4..<Int(length+4)], as: encoding)
        return (length + 4, result)
    }
    
    func toUTF8PaddedString() -> [UInt8] {
        let length = UInt32(self.count)
        var result = length.bigEdianBytes
        let data = self.data(using: .utf8) ?? Data()
        result.append(contentsOf: Array(data))
        return result
    }
}

