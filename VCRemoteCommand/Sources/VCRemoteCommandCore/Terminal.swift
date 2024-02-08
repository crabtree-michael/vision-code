//
//  File.swift
//  
//
//  Created by Michael Crabtree on 2/7/24.
//

import Foundation
import NIOCore
import NIOSSH

public struct RCPseudoTerminalSettings {
    let pixelSize: CGSize
    let characterSize: CGSize
    let term: String
    
    public init(pixelSize: CGSize, characterSize: CGSize, term: String) {
        self.pixelSize = pixelSize
        self.characterSize = characterSize
        self.term = term
    }
}

class PseudoTerminal: SSHChildChannelHandler {
    internal var onReceived: ((_ bytes: ArraySlice<UInt8>) -> ())? = nil
    internal var hasInitialized: Bool = false
    internal let settings: RCPseudoTerminalSettings

    init(settings: RCPseudoTerminalSettings, eventLoop: EventLoop) {
        self.settings = settings
        super.init(eventLoop: eventLoop)
    }
 
    override func activate(context: ChannelHandlerContext) {
        // When channel becomes active, we request to request to allocate the terminal
        let execRequest = SSHChannelRequestEvent.PseudoTerminalRequest(wantReply: true,
                                                                       term: settings.term,
                                                                       terminalCharacterWidth: Int(settings.characterSize.width),
                                                                       terminalRowHeight: Int(settings.characterSize.height),
                                                                       terminalPixelWidth: Int(settings.pixelSize.width),
                                                                       terminalPixelHeight: Int(settings.pixelSize.height),
                                                                       terminalModes: .init([:]))
        _ = context.triggerUserOutboundEvent(execRequest).always { result in
            switch(result) {
            case .success:
                // Now we can start the shell
                let shell = SSHChannelRequestEvent.ShellRequest(wantReply: true)
                context.triggerUserOutboundEvent(shell).whenFailure({ error in
                    self.creationPromise.fail(error)
                })
            case .failure(let error):
                self.creationPromise.fail(error)
            }
        }
    }
    
    override func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        if !self.hasInitialized {
            self.hasInitialized = true
            self.creationPromise.succeed()
        }
        let data = self.unwrapInboundIn(data)
        
        guard case .byteBuffer(var bytes) = data.data else {
            return
        }
        
        self.onReceived?(ArraySlice<UInt8>(bytes.readBytes(length: bytes.readableBytes)!))
    }
    
    func setSize(terminalCharacterWidth: Int, terminalRowHeight: Int, terminalPixelWidth: Int, terminalPixelHeight: Int)  throws -> EventLoopPromise<Void> {
        guard let context = self.context else {
            throw ShellError.notPrepared
        }
        
        let promise = context.eventLoop.makePromise(of: Void.self)
        context.eventLoop.execute {
            context.triggerUserOutboundEvent(
                SSHChannelRequestEvent.WindowChangeRequest(
                    terminalCharacterWidth: terminalCharacterWidth,
                    terminalRowHeight: terminalRowHeight,
                    terminalPixelWidth: terminalPixelWidth,
                    terminalPixelHeight: terminalPixelHeight), promise: promise)
        }
        
        return promise
    }
    
    func send(_ bytes: ArraySlice<UInt8>) throws -> EventLoopPromise<Void> {
        guard let context = context else {
            throw ShellError.notPrepared
        }
        
        let promise = context.eventLoop.makePromise(of: Void.self)
        let buffer = ByteBuffer(bytes: bytes)
        let result = SSHChannelData(type: .channel, data: .byteBuffer(buffer))
        context.eventLoop.execute {
            context.writeAndFlush(self.wrapOutboundOut(result), promise: promise)
        }
        
        return promise
    }
}

public class RCPseudoTerminal {
    public  var onReceived: ((_ bytes: ArraySlice<UInt8>) -> ())? {
        set {
            self.handler.onReceived = newValue
        }
        get {
            return self.handler.onReceived
        }
    }
    
    internal var creationPromise: EventLoopPromise<Void> {
        get {
            return self.handler.creationPromise
        }
    }
    
    internal let handler:PseudoTerminal
    
    init(settings: RCPseudoTerminalSettings, eventLoop: EventLoop) {
        self.handler = PseudoTerminal(settings: settings, eventLoop: eventLoop)
    }
    
    public func send(_ bytes: ArraySlice<UInt8>) async throws  {
        return try await self.handler.send(bytes).futureResult.get()
    }
    
    public func setSize(terminalCharacterWidth: Int, terminalRowHeight: Int, terminalPixelWidth: Int, terminalPixelHeight: Int) async throws {
        return try await self.handler.setSize(terminalCharacterWidth: terminalCharacterWidth,
                                              terminalRowHeight: terminalRowHeight,
                                              terminalPixelWidth: terminalPixelWidth, 
                                              terminalPixelHeight: terminalPixelHeight).futureResult.get()
    }
}
