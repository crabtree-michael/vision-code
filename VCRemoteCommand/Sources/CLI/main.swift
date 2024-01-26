//
//  File.swift
//  
//
//  Created by Michael Crabtree on 1/20/24.
//

import Foundation
import VCRemoteCommandCore

func simpleShell(shell: RCShell) async {
    while true {
        print("> ", terminator: "")
        let cmd = readLine()
        guard let cmd = cmd else {
            print("Finished input")
            return
        }
        let result = try! await shell.execute(cmd)
        if result.stdOut.count > 0 {
            print(result.stdOut)
        }
        if result.stdErr.count > 0 {
            print(result.stdErr)
        }
        
    }
}

let file = "/Users/michael/Documents/Car/IMG_1931.jpeg"
let connection = RCConnection(host: "192.168.88.236", port: 22, username: "michael", password: "rect")
try! await connection.connect()
let client = try! await connection.createSFTPClient()

await withTaskGroup(of: Void.self) { group in

    group.addTask {
        for _ in (0..<100) {
            let t = Task {
                do {
                    try await Task.sleep(nanoseconds: UInt64(2 * 1_000_000_000))
                    try Task.checkCancellation()
                    fatalError("LS stopped")
                } catch {
                    
                }

            }
            print("Get LS \(ProcessInfo.processInfo.systemUptime)")
            let data = try! await client.list(path: "/")
            print("Got LS \(ProcessInfo.processInfo.systemUptime)")
            t.cancel()
        }
        //            timer.invalidate()
        
    }

    group.addTask {
        for _ in (0..<100) {
            let t = Task {
                do {
                    try await Task.sleep(nanoseconds: UInt64(2 * 1_000_000_000))
                    try Task.checkCancellation()
                    fatalError("File stopped")
                } catch {
                    
                }

            }
            print("Get file \(ProcessInfo.processInfo.systemUptime)")
            let data = try! await client.get(file: file)
            print("Got file \(ProcessInfo.processInfo.systemUptime)")
            t.cancel()
        }

    }

    // Wait for both tasks to finish
    for await _ in group {}
}


//let data = try! await client.get(file: file)
//print(data.count)
//let content = String(decoding: data, as: UTF8.self)
//let writeMessage = "JOE!"
//let d = Data(writeMessage.utf8)
//print("Write")
//try! await client.write(d, file: file)

print("Connection succesful!")

