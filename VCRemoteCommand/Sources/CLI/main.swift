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
print("Creating shell...")
let client = try! await connection.createShell()
print("Executing...")
let result = try! await client.execute("pwd\n")
print(result.stdOut, result.stdErr)
