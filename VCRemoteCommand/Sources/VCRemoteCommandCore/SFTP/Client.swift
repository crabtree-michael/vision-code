//
//  File.swift
//  
//
//  Created by Michael Crabtree on 1/22/24.
//

import Foundation

import NIOSSH
import NIOCore
import NIOPosix
import Dispatch

public enum SFTPError: Error, LocalizedError {
    case notPrepared
    case malformedMessage
    case unsupportedMessage
    case unsupportedServer
    case unexpectedResponse
    case closedHandle
    case serverSuppliedError(message: String)
    case timeout
    
    public var errorDescription: String? {
        switch(self) {
        case .serverSuppliedError(let message):
            return message
        case .notPrepared:
            return "Connection was not ready"
        case .malformedMessage:
            return "Received unexpected reply"
        case .unsupportedMessage:
            return "Message type is not supported"
        case .unsupportedServer:
            return "This server is not supported."
        case .unexpectedResponse:
            return "The response was not expected"
        case .closedHandle:
            return "Handle is already closed"
        case .timeout:
            return "The request timed out"
        }
        
    }
}

class SFTPHandler: ChannelDuplexHandler {
    private static let supportedVersion: UInt32 = 3
    
    typealias InboundIn = SFTPMessage
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = ByteBuffer
    typealias OutboundOut = SFTPMessage
    
    internal let creationPromise: EventLoopPromise<Void>
    internal var context:ChannelHandlerContext?
    
    internal var wroteInit: Bool = false
    
    var promise: EventLoopPromise<String>? = nil
    
    private var responseMap: [UInt32:SFTPResponse] = [:]
    private var responseMapLock = NSLock()
    
    private var chunkSize: UInt32 = 1000000
    
    private let mapLock = NSLock()
    
    var timeout: TimeInterval = 30
    
    
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
        let subsystemRequest = SSHChannelRequestEvent.SubsystemRequest(subsystem: "sftp", wantReply: true)
        context.triggerUserOutboundEvent(subsystemRequest).whenFailure { error in
            self.creationPromise.fail(error)
        }
    }
    
    func channelWritabilityChanged(context: ChannelHandlerContext) {
        if context.channel.isWritable && !self.wroteInit {
            self.writeInitMessage()
        }
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let wrappedData = self.unwrapInboundIn(data)
        
        switch(wrappedData) {
        case let message as SFTPVersionMessage:
            self.finishInitialization(message: message)
        case let message as SFTPFullMessage:
            self.completeRequest(withMessage: message)
        default:
            print("Could not read \(data)")
            context.fireChannelRead(data)
        }
    }

    
    private func writeInitMessage() {
        self.wroteInit = true
        let message = SFTPInitRequest(version: SFTPHandler.supportedVersion)
        context?.writeAndFlush(self.wrapOutboundOut(message)).whenFailure({ error in
            self.creationPromise.fail(error)
        })
    }
    
    private func finishInitialization(message: SFTPVersionMessage) {
        guard message.version <= SFTPHandler.supportedVersion else {
            self.creationPromise.fail(SFTPError.unsupportedServer)
            return
        }
        
        self.creationPromise.succeed()
        return
    }
   
    func open(dir: String) async throws -> SFTPHandleResponse {
        return try await self.executeRequest { id in
            SFTPOpenDirRequest(requestId: id, path: dir)
        }
    }
    
    func open(path: String, permissions: SFTPPermission) async throws -> SFTPHandleResponse {
        return try await self.executeRequest { id in
            SFTPOpenFileRequest(requestId: id, path: path, permissions: permissions)
        }
    }
    
    func read(handle: String, offset: UInt64) async throws -> SFTPReadResponse {
        return try await self.executeRequest { id in
            SFTPReadRequest(requestId: id, handle: handle, offset: offset, length: self.chunkSize)
        }
    }
    
    func readDir(handle: String) async throws -> SFTPReadDirResponse {
        return try await self.executeRequest() { id in
            SFTPReadDirRequest(requestId: id, handle: handle)
        }
    }
    
    func write(to handle: String, data: Data, offset: UInt64) async throws -> SFTPStatusResponse {
        return try await self.executeRequest { id in
            SFTPWriteRequest(requestId: id, handle: handle, data: data, offset: offset)
        }
    }
    
    func close(handle: String) async throws -> SFTPCloseResponse {
        return try await self.executeRequest { id in
            SFTPCloseRequest(requestId: id, handle: handle)
        }
    }
    
    func fstat(handle: String) async throws -> SFTPStatResponse {
        return try await self.executeRequest { id in
            SFTPFStatRequest(requestId: id, handle: handle)
        }
    }
    
    func mkdir(path: String) async throws -> SFTPMkDirResponse {
        return try await self.executeRequest { id in
            SFTPMkDirRequest(requestId: id, path: path)
        }
    }
    
    private func executeRequest<T>(_ request: @escaping (_ id: UInt32) -> SFTPMessage) async throws -> T where T:SFTPResponse {
        guard let context = self.context, self.wroteInit else {
            throw SFTPError.notPrepared
        }
        let response = self.makeExpectedResponse(context: context, of: T.self)
        let id = response.id
        
        let timeout = self.timeout
        var timeoutTask: Task<Void, Never>?
        if timeout > 0 {
            timeoutTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                response.promise.fail(SFTPError.timeout)
            }
        }
        
        context.eventLoop.execute({
            let data = self.wrapOutboundOut(request(id))
            context.writeAndFlush(data).whenFailure { error in
                print("Failure")
                response.promise.fail(error)
            }
        })
        
        try await response.promise.futureResult.get()
        timeoutTask?.cancel()
        return response
    }
    
    private func completeRequest(withMessage message: SFTPFullMessage) {
        mapLock.lock()
        guard let response = self.responseMap[message.requestID] else {
            print("Got response for unknown request \(message.requestID)")
            return
        }

        do {
            try response.complete(with: message)
        } catch (let error) {
            response.promise.fail(error)
        }
        
       
        self.responseMap.removeValue(forKey: message.requestID)
        mapLock.unlock()
    }
    
    private func makeExpectedResponse<T>(context: ChannelHandlerContext, of: T.Type) -> T where T:SFTPResponse{
        let id = UInt32(Int.random(in: 0..<Int.maxUInt32))
        let promise = context.eventLoop.makePromise(of: Void.self)
        let response = T(id: id, promise: promise)
        mapLock.lock()
        self.responseMap[id] = response
        mapLock.unlock()
        return response
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("Error \(error)")
    }
    
    func close() async throws {
        guard let context = self.context else {
            return
        }
        
        let promise = context.eventLoop.makePromise(of: Void.self)
        self.context?.eventLoop.execute {
            self.close(context: context, mode: .all, promise: promise)
        }
        _ = try await promise.futureResult.get()
    }
}

public protocol HandleResponse {
    func getHandle() -> String?
}

public class ListResponse: HandleResponse {
    public let files: [File]
    public var hasMore: Bool {
        get {
            return handle != nil
        }
    }
    internal let handle: String?
    
    internal init(files: [File], handle: String?) {
        self.files = files
        self.handle = handle
    }
    
    public func getHandle() -> String? {
        return self.handle
    }
}

public class Handle: HandleResponse {
    internal let handle: String?
    
    internal init(handle: String?) {
        self.handle = handle
    }
    
    public func getHandle() -> String? {
        return self.handle
    }
}

public class RCSFTPClient {
    internal var handlers: [ChannelHandler] {
        get {
            return [outboundHandler, inboundHandler, handler ]
        }
    }
    
    private let inboundHandler = SFTPMessageInboundTransformer()
    private let outboundHandler = SFTPMessageOutboundTransformer()
    private let handler: SFTPHandler
    
    internal var creationPromise: EventLoopPromise<Void> {
        get {
            return self.handler.creationPromise
        }
    }
    
    var requestTimeout: TimeInterval {
        get {
            handler.timeout
        }
        set {
            handler.timeout = newValue
        }
    }
    
    init(eventLoop: EventLoop) {
        self.handler = SFTPHandler(eventLoop: eventLoop)
    }
    
    public func close() async throws {
        try await self.handler.close()
    }
    
    public func get(file: String) async throws -> Data {
        let h = try await self.handler.open(path: file, permissions: .READ)
        let handle = Handle(handle: h.handle)
        let data = try await self.get(handle: handle)
        
        do {
            _ = try await self.handler.close(handle: h.handle)
        } catch {
            print("Failed to close handle for \(file)")
        }

        
        return data
    }
    
    public func get(handle: HandleResponse) async throws -> Data {
        guard let handle = handle.getHandle() else {
            throw SFTPError.notPrepared
        }
        
        var result = Data()
        var response = try await self.handler.read(handle: handle, offset: 0)
        result.append(response.data)
        while !response.reachedEOF {
            response = try await self.handler.read(handle: handle, offset: UInt64(result.count))
            result.append(response.data)
        }
        
        return result
    }
    
    public func exists(file: String) async throws -> Bool {
        var r: HandleResponse?
        do {
            r = try await self.open(file: file, permissions: [.READ])
        } catch {
            if let error = error as? SFTPError {
                switch(error) {
                case (.serverSuppliedError(_)):
                    return false
                default:
                    break
                }
            }
        }
        if let r = r {
            _ = try await self.close(response: r)
        }
        return true
    }
    
    public func open(file: String, permissions: SFTPPermission = [.TRUNC, .CREAT, .WRITE]) async throws -> Handle {
        let sftpHandle = try await self.handler.open(path: file, permissions: permissions)
        return Handle(handle: sftpHandle.handle)
    }
    
    public func stat(handle: HandleResponse) async throws -> FileAttributes {
        guard let handle = handle.getHandle() else {
            throw SFTPError.notPrepared
        }
        
        let response = try await self.handler.fstat(handle: handle)
        return response.attributes!
    }
    
    public func write(_ data: Data, handle: HandleResponse) async throws {
        guard let handle = handle.getHandle() else {
            throw SFTPError.notPrepared
        }
        
        _ = try await self.handler.write(to: handle, data: data, offset: 0)
    }
    
    public func write(_ data: Data, file: String, permissions: SFTPPermission = [.TRUNC, .CREAT, .WRITE]) async throws {
        let h = try await self.handler.open(path: file, permissions: permissions)
        let handle = Handle(handle: h.handle)
        try await self.write(data, handle: handle)
        
        do {
            _ = try await self.handler.close(handle: h.handle)
        } catch {
            print("Failed to close handle for file \(file)")
        }

    }
    
    public func list(path: String) async throws -> ListResponse {
        let handle = try await self.handler.open(dir: path)
        let response = try await self.handler.readDir(handle: handle.handle)
        let finalResult = try await self.handler.readDir(handle: handle.handle)
        var resultHandle: String? = handle.handle
        if finalResult.loadedAllFiles {
            do {
                _ = try await self.handler.close(handle: handle.handle)
                
            } catch (let error) {
                print("Failed to close handle for \(path): \(error)")
            }

            
            resultHandle = nil
        }
        
        let result = ListResponse(files: response.files + finalResult.files,
                                  handle: resultHandle)

        return result
    }
    
    public func append(to response: ListResponse) async throws -> ListResponse {
        guard let handle = response.handle else {
            throw SFTPError.closedHandle
        }
        let result = try await self.handler.readDir(handle: handle)
        return ListResponse(files: response.files + result.files, 
                            handle: result.loadedAllFiles ? nil : response.handle)
    }
    
    public func close(response: HandleResponse) async throws {
        guard let handle = response.getHandle() else {
            throw SFTPError.closedHandle
        }
        
        _ = try await self.handler.close(handle: handle)
    }
    
    public func makeDirectory(at path: String) async throws {
        _ = try await self.handler.mkdir(path: path)
    }
}
