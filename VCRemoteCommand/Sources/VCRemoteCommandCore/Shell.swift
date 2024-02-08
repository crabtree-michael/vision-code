//
//  File.swift
//  
//
//  Created by Michael Crabtree on 1/21/24.
//

import Foundation
import NIOSSH
import NIOCore
import NIOPosix
import Dispatch

typealias RCCloseHandle = () -> Void

class SSHChildChannelHandler: ChannelDuplexHandler {
    typealias InboundIn = SSHChannelData
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = ByteBuffer
    typealias OutboundOut = SSHChannelData
    
    
    internal let creationPromise: EventLoopPromise<Void>
    internal var context:ChannelHandlerContext?
    
    internal var isWritable: Bool? = nil
    
    internal var onClose: RCCloseHandle?
    
    init(eventLoop: EventLoop) {
        self.creationPromise = eventLoop.makePromise()
    }
    
    func handlerAdded(context: ChannelHandlerContext) {
        context.channel.setOption(ChannelOptions.allowRemoteHalfClosure, value: true).whenFailure { error in
            self.creationPromise.fail(error)
        }
    }
    
    func channelActive(context: ChannelHandlerContext) {
        self.context = context
        self.activate(context: context)
    }
    
    func activate(context: ChannelHandlerContext) {
        // Implement logic here
    }
    
    func channelReadComplete(context: ChannelHandlerContext) {
        context.fireChannelReadComplete()
    }
    
    func channelWritabilityChanged(context: ChannelHandlerContext) {
        if context.channel.isWritable {
            self.creationPromise.succeed()
        }
        self.isWritable = context.channel.isWritable
    }
    
    func channelInactive(context: ChannelHandlerContext) {
        print("Connection closed")
        self.onClose?()
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        context.fireChannelRead(data)
    }
}

class ShellChannelHandler: SSHChildChannelHandler {
    override func activate(context: ChannelHandlerContext) {
        // When channel becomes active, we request to create the shell
        let execRequest = SSHChannelRequestEvent.ShellRequest(wantReply: true)
        context.triggerUserOutboundEvent(execRequest).whenFailure { err in
            self.creationPromise.fail(err)
        }
    }
    
    func execute(cmd: String) throws -> EventLoopPromise<RCCommandResult> {
        guard let context = self.context, self.isWritable ?? false else {
            throw ShellError.notPrepared
        }
        
        let cmd = Command(cmd, promise: context.eventLoop.makePromise())
        context.eventLoop.execute {
            let _ = context.channel.pipeline.addHandler(cmd).whenFailure { error in
                cmd.promise.fail(error)
            }
            let _ = cmd.promise.futureResult.always { _ in
                let _  = context.pipeline.removeHandler(cmd)
            }
        }

        return cmd.promise
    }
}

public class RCShell {
    internal var creationPromise: EventLoopPromise<Void> {
        get {
            return self.handler.creationPromise
        }
    }
    
    internal let handler:ShellChannelHandler
    
    private var stdInByteBuffer = ByteBuffer()
    
    public var onClose: (() -> Void)?
    
    init(eventLoop: EventLoop) {
        self.handler = ShellChannelHandler(eventLoop: eventLoop)
        self.handler.onClose = {
            self.onClose?()
        }
    }
    
    public func execute(_ cmd: String) async throws -> RCCommandResult   {
        return try await self.handler.execute(cmd: cmd).futureResult.get()
    }
}
