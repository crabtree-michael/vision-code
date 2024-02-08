//
//  TrieNodeTests.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/8/24.
//

import XCTest

final class TrieNodeTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInsert() throws {
        let node = TrieNode<String, String>()
        node.insert(value: "Goodbye", for: "Hello")
        assert(node.branches["h"] != nil)
        assert(node.retrieve(key: "Hello") == ["Goodbye"])
    }

}
