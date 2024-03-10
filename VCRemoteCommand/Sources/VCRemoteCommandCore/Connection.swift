// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation
import NIOSSH
import NIOCore
import NIOPosix
import Dispatch

public class RCConnection: NIOSSHClientUserAuthenticationDelegate, NIOSSHClientServerAuthenticationDelegate   {
    var host: String
    var port: Int
    var username: String
    var password: String
    
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private var channel: Channel?
    private var calledAuth: Bool = false
    
    let buffer = ByteBufferAllocator()
    
    public init(host: String, port: Int, username: String, password: String) {
        self.host = host
        self.port = port
        self.username = username
        self.password = password
    }
    
    public func connect(onDisconnect: ((Result<Void, Error>) -> ())? = nil) async throws {
        let bootstrap = ClientBootstrap(group: self.group)
            .channelInitializer { channel in
                channel.pipeline.addHandlers([NIOSSHHandler(
                    role: .client(.init(userAuthDelegate: self, serverAuthDelegate: self)),
                    allocator: channel.allocator, inboundChildChannelInitializer: nil)])
            }
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(IPPROTO_TCP), TCP_NODELAY), value: 1)
        
        let channel = try await withCheckedThrowingContinuation { continuation in
            let _ = bootstrap.connect(host: host, port: port).always { result in
                switch(result) {
                case .success(let channel):
                    continuation.resume(returning: channel)
                case .failure(let err):
                    continuation.resume(throwing: err)
                }
            }
        }
        
        self.channel = channel
        self.channel?.closeFuture.whenComplete({ result in
            onDisconnect?(result)
        })
    }
    
    public func createTerminal(settings: RCPseudoTerminalSettings) async throws -> RCPseudoTerminal {
        guard let channel = self.channel else {
            throw ConnectionError.noActiveChannel
        }
        
        let p = self.callWithTimeout({
            let terminal = RCPseudoTerminal(settings: settings, eventLoop: channel.eventLoop)
            let _ = try self.createChildChannel(withHandlers: [terminal.handler])
            let _ = try await terminal.creationPromise.futureResult.get()
            return terminal
        }, timeout: 15)
        

        return try await p.futureResult.get()
    }
    
    public func createShell() async throws -> RCShell {
        guard let channel = self.channel else {
            throw ConnectionError.noActiveChannel
        }
        
        let p = self.callWithTimeout({
            let shell = RCShell(eventLoop: channel.eventLoop)
            let _ = try self.createChildChannel(withHandlers: [shell.handler])
            let _ = try await shell.creationPromise.futureResult.get()
            return shell
        }, timeout: 15)
        
        return try await p.futureResult.get()
    }
    
    public func createSFTPClient() async throws -> RCSFTPClient {
        guard let channel = self.channel else {
            throw ConnectionError.noActiveChannel
        }
        
        let p = self.callWithTimeout({
            let client = RCSFTPClient(eventLoop: channel.eventLoop)
            let _ = try self.createChildChannel(withHandlers: client.handlers)
            let _ = try await client.creationPromise.futureResult.get()
            return client
        }, timeout: 15)
        
        return try await p.futureResult.get()
    }
    
    private func createChildChannel(withHandlers handlers: [ChannelHandler]) throws -> EventLoopFuture<Channel>  {
        guard let channel = self.channel else {
            throw ConnectionError.noActiveChannel
        }
        
        return channel.pipeline.handler(type: NIOSSHHandler.self).flatMap { handler in
            let p = channel.eventLoop.makePromise(of: Channel.self)
            handler.createChannel(p) { childChannel, channelType in
                guard channelType == .session else {
                    return channel.eventLoop.makeFailedFuture(ConnectionError.incorrectChannelType)
                }
                childChannel.closeFuture.whenComplete { result in
                    print("Child closed")
                }
                return childChannel.pipeline.addHandlers(handlers)
            }
            return p.futureResult
        }
    }
    
    private func callWithTimeout<T>(_ closure: @escaping () async throws -> T, timeout: TimeInterval) -> EventLoopPromise<T> {
        let promise = self.channel!.eventLoop.makePromise(of: T.self)
        Task {
            var timeoutTask: Task<Void, Never>?
            if timeout > 0 {
                timeoutTask = Task {
                    try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                    promise.fail(SFTPError.timeout)
                }
            }
            let result = try await closure()
            timeoutTask?.cancel()
            promise.succeed(result)
        }
        
        return promise
    }
    
    public func nextAuthenticationType(availableMethods: NIOSSH.NIOSSHAvailableUserAuthenticationMethods, nextChallengePromise: NIOCore.EventLoopPromise<NIOSSH.NIOSSHUserAuthenticationOffer?>) {
        guard availableMethods.contains(.password) else {
            nextChallengePromise.fail(ConnectionError.passwordAuthNotAvailable)
            return
        }
        
        guard !calledAuth else {
            nextChallengePromise.succeed(.none)
            return
        }
        
        calledAuth = true
        nextChallengePromise.succeed(
            NIOSSHUserAuthenticationOffer(username: self.username,
                                          serviceName: "VisionCode",
                                          offer: .password(.init(password: self.password))))
    }
    
    public func validateHostKey(hostKey: NIOSSH.NIOSSHPublicKey, validationCompletePromise: NIOCore.EventLoopPromise<Void>) {
        validationCompletePromise.succeed()
    }
    
    public func close() {
        _ = self.channel?.close()
    }
}
