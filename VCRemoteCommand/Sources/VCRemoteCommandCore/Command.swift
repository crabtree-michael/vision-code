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

enum ConnectionError: Error {
    case passwordAuthNotAvailable
    case incorrectChannelType
    case noActiveChannel
}

enum CommandError: Error {
    case unexpectedDataTypeReceived
    case channelIsInactive
}

public class RCCommandResult {
    public let stdOut: String
    public let stdErr: String
    
    init(stdOut: String, stdErr: String) {
        self.stdOut = stdOut
        self.stdErr = stdErr
    }
}

enum ShellError: Error {
    case notPrepared
}

class Command: ChannelDuplexHandler, RemovableChannelHandler {
    private let command: String
    private let buffer: ByteBuffer
    let promise: EventLoopPromise<RCCommandResult>
    
    typealias InboundIn = SSHChannelData
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = ByteBuffer
    typealias OutboundOut = SSHChannelData
    
    private var stdOutBuffer = ByteBuffer()
    private var stdErrBuffer = ByteBuffer()
    private let status:Int? = nil
    
    private static let cmdEndStr = "COMMANDOVERANDDONE"
    private static let finishEcho = "; echo " + cmdEndStr
    private static let terminator = "\n"
    
    private static func cmdData(_ cmd: String) -> Data {
        let fullCmd = cmd + finishEcho + terminator
        return Data(fullCmd.utf8)
    }
    
    init(_ cmd: String, promise: EventLoopPromise<RCCommandResult>) {
        self.command = cmd
        self.buffer = .init(data: Command.cmdData(self.command))
        self.promise = promise
    }
    
    func handlerAdded(context: ChannelHandlerContext) {
        self.execute(in: context)
    }
    
    func execute(in context: ChannelHandlerContext) {
        let request = self.wrapOutboundOut(SSHChannelData(type: .channel, data: .byteBuffer(self.buffer)))
        context.writeAndFlush(request).whenFailure { error in
            self.promise.fail(error)
        }
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        self.promise.fail(error)
    }
    
    func channelReadComplete(context: ChannelHandlerContext) {
        let stdErr = String(self.stdErrBuffer.readString(length: stdErrBuffer.readableBytes)?.dropLast(1) ?? "")
        let result = RCCommandResult(stdOut: self.stdOutput(), stdErr: stdErr)
        self.promise.succeed(result)
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let data = self.unwrapInboundIn(data)
        
        guard case .byteBuffer(var bytes) = data.data else {
            self.promise.fail(CommandError.unexpectedDataTypeReceived)
            return
        }
        
        switch data.type {
        case .channel:
            self.stdOutBuffer.writeBuffer(&bytes)
        case .stdErr:
            self.stdErrBuffer.writeBuffer(&bytes)
        default:
            context.fireChannelRead(self.wrapInboundOut(bytes))
        }
    }
    
    func channelInactive(context: ChannelHandlerContext) {
        self.promise.fail(CommandError.channelIsInactive)
    }
    
    private func stdOutput() -> String {
        guard let output = self.stdOutBuffer.readString(length: stdOutBuffer.readableBytes) else {
            return ""
        }
        
        return Command.cleanStdOut(output: output)
    }
    
    private static func cleanStdOut(output: String) -> String {
        let additionalEntry = cmdEndStr + terminator + terminator
        guard output.count >= additionalEntry.count else {
            return ""
        }
        
        return String(output.dropLast(additionalEntry.count))
    }
}
