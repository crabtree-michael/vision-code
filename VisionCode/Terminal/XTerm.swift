//
//  XTerm.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/7/24.
//

import Foundation
import SwiftUI
import SwiftTerm
import VCRemoteCommandCore
import Combine

class XTermViewController: UIViewController, TerminalViewDelegate, ConnectionUser {
    var connection: Connection
    let terminalView = SwiftTerm.TerminalView(frame: CGRect(x: 100, y: 100, width: 800, height: 800))
    var shell: RCPseudoTerminal?
    
    var currentDirectory: String
    
    private let identifier: UUID
    private var tasks = [AnyCancellable]()
    private let root: String
    
    init(connection: Connection, root: String) {
        self.connection = connection
        self.identifier = UUID()
        self.root = root
        self.currentDirectory = root
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.view.addSubview(terminalView)
        terminalView.translatesAutoresizingMaskIntoConstraints = false
        
        terminalView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        terminalView.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = true
        terminalView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        terminalView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        terminalView.backgroundColor = .clear
        terminalView.nativeForegroundColor = .white
        terminalView.nativeBackgroundColor = .black
        
        terminalView.terminalDelegate = self
        
        self.load()
    }
    
    func gotData(_ bytes: ArraySlice<UInt8>) {
        terminalView.feed(byteArray: bytes)
    }
    
    func sizeChanged(source: SwiftTerm.TerminalView, newCols: Int, newRows: Int) {
        Task {
            if let shell = self.shell {
                try! await shell.setSize(terminalCharacterWidth: newCols, terminalRowHeight: newRows, terminalPixelWidth: Int(terminalView.contentSize.width), terminalPixelHeight: Int(terminalView.contentSize.height))
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        if let shell = self.shell {
            Task {
                let dims = self.terminalView.getTerminal().getDims()
                try await shell.setSize(terminalCharacterWidth: dims.cols, terminalRowHeight: dims.rows, terminalPixelWidth: Int(terminalView.contentSize.width), terminalPixelHeight: Int(terminalView.contentSize.height))
            }
        }

    }
    
    func setTerminalTitle(source: SwiftTerm.TerminalView, title: String) {
        // TODO: Implement me
    }
    
    func hostCurrentDirectoryUpdate(source: SwiftTerm.TerminalView, directory: String?) {
        // TODO: Implement me
        if let directory = directory {
            self.currentDirectory = directory
        }
    }
    
    func send(source: SwiftTerm.TerminalView, data: ArraySlice<UInt8>) {
        Task {
            do {
                try await self.shell?.send(data)
            } catch {
                self.feedDisconnected()
            }
        }
    }
    
    func scrolled(source: SwiftTerm.TerminalView, position: Double) {
        // TODO: Implement me
    }
    
    func requestOpenLink(source: SwiftTerm.TerminalView, link: String, params: [String : String]) {
        // TODO: Implement me
    }
    
    func clipboardCopy(source: SwiftTerm.TerminalView, content: Data) {
        let str = content.base64EncodedString()
        UIPasteboard.general.string = str
    }
    
    func rangeChanged(source: SwiftTerm.TerminalView, startY: Int, endY: Int) {
        // TODO: Implement me
    }
    
    func id() -> String {
        self.identifier.uuidString
    }
    
    func connectionDidReload(_ connection: Connection) {
        self.connection = connection
        self.subscribeToConnectionChanges()
        
        self.load()
    }
    
    func load() {
        self.terminalView.feed(text: "\n \r [CONNECTING] \n \r")
        Task {
            let t = terminalView.getTerminal()
            let dims = t.getDims()
            
            do {
                self.shell = try await connection.createPTY(user: self, settings: RCPseudoTerminalSettings(
                    pixelSize: terminalView.frame.size,
                    characterSize: CGSize(width: dims.cols, height: dims.rows),
                    term: "xterm-256color"
                ))
                self.shell!.onReceived = { bytes in
                    Task {
                        await MainActor.run {
                            self.gotData(bytes)
                        }
                    }
                }
                
                if let cdCmd = "cd \(self.currentDirectory)\n".data(using: .utf8) {
                    try await self.shell?.send(ArraySlice(cdCmd))
                }
                
                
                try await self.shell!.setSize(terminalCharacterWidth: dims.cols, terminalRowHeight: dims.rows, terminalPixelWidth: Int(terminalView.contentSize.width), terminalPixelHeight: Int(terminalView.contentSize.height))
            } catch {
                self.feedDisconnected()
            }
        }
    }
    
    func subscribeToConnectionChanges() {
        self.connection.state.$status.sink { state in
            switch(state) {
            case .failed(_):
                self.feedDisconnected()
            default: break
            }
        }.store(in: &self.tasks)
    }
    
    func feedDisconnected() {
        self.terminalView.feed(text: "\n [DISCONNECTED] \n")
    }
    
}

struct XTerm: UIViewControllerRepresentable {
    typealias UIViewControllerType = XTermViewController
    
    @State var connection: Connection
    let rootDirectory: String
    
    func makeUIViewController(context: Context) -> XTermViewController {
        let controller = XTermViewController(connection: connection, root: rootDirectory)
        return controller
    }

    func updateUIViewController(_ uiViewController: XTermViewController, context: Context) {
//        uiViewController.onTextChanges = { text in
//            self.text = text
//        }
//        uiViewController.update(text, language: language)
    }
}
