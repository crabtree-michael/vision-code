//
//  File 2.swift
//  
//
//  Created by Michael Crabtree on 1/23/24.
//

import Foundation
import NIOCore
import NIOSSH

class SFTPMessageInboundTransformer: ChannelInboundHandler {
    private var incomingMessage: SFTPDataMessage?
    private var incomingBytesLeft: Int?
    
    typealias InboundIn = SSHChannelData
    typealias InboundOut = SFTPMessage
    
    func produceMessage(from bytes: inout ByteBuffer) throws -> SFTPMessage? {
        guard incomingMessage == nil else {
            return self.processIncoming(bytes: &bytes)
        }
        
        let readableBytes = bytes.readableBytes
        guard let b = bytes.readBytes(length: 4) else {
            throw SFTPError.malformedMessage
        }
        let length = UInt32.from(bytes: b.reversed())
        
        guard let b = bytes.readBytes(length: 1),
              let t = b.first else {
            throw SFTPError.malformedMessage
        }
        let type = SFTPMessageType(rawValue: t)
        
        switch(type) {
        case .DATA:
            let message = try SFTPDataMessage(buffer: &bytes, length: length)
            let delta = Int(length) - readableBytes
            if delta > 0 {
                self.incomingMessage = message
                self.incomingBytesLeft = delta
                return nil
            }
            return message
        case .ATTRS:
            let message = try SFTPAttrMessage(buffer: &bytes, length: length)
            return message
        case .VERSION:
            let body = bytes.readData(length: bytes.readableBytes) ?? Data()
            return SFTPVersionMessage(length: length, type: type, body: body)
        case .STATUS:
            let body = bytes.readData(length: bytes.readableBytes) ?? Data()
            return SFTPStatusMessage(length: length, type: type, body: body)
        case .HANDLE:
            let body = bytes.readData(length: bytes.readableBytes) ?? Data()
            return SFTPHandleMessage(length: length, type: type, body: body)
        case .NAME:
            let body = bytes.readData(length: bytes.readableBytes) ?? Data()
            return SFTPNameMessage(length: length, type: type, body: body)
        default:
            print("Unsupported \(type)")
            throw SFTPError.unsupportedMessage
        }
    }
    
    func channelReadComplete(context: ChannelHandlerContext) {
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let data = self.unwrapInboundIn(data)
        guard case .byteBuffer(var bytes) = data.data else {
            context.fireErrorCaught(SFTPError.malformedMessage)
            return
        }
        
        do {
            if let message = try self.produceMessage(from: &bytes) {
                context.fireChannelRead(self.wrapInboundOut(message))
            }
        } catch (let error) {
            context.fireErrorCaught(error)
        }
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("Error \(error)")
    }
    
    func processIncoming(bytes: inout ByteBuffer) -> SFTPMessage? {
        let length = bytes.readableBytes
        guard let message = self.incomingMessage,
                let data = bytes.readBytes(length: length)  else {
            return nil
        }

        message.messageData.append(contentsOf: data)
        self.incomingBytesLeft = (self.incomingBytesLeft ?? 0) - length
        if self.incomingBytesLeft ?? 0 <= 0 {
            self.incomingMessage = nil
            self.incomingBytesLeft = nil
            return message
        }
        
        return nil
    }
}

class SFTPMessageOutboundTransformer: ChannelOutboundHandler {
    typealias OutboundIn = SFTPMessage
    typealias OutboundOut = SSHChannelData
    
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let data = self.unwrapOutboundIn(data)
        let outbound = self.wrapOutboundOut(SSHChannelData(type: .channel, data: .byteBuffer(data.buffer())))
        context.write(outbound, promise: promise)
    }
}
