//
//  Host.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import RealmSwift

class Host: Object, Identifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var name: String = ""
    @Persisted var ipAddress: String = ""
    @Persisted var port: Int = 0
    @Persisted var username: String = ""
    @Persisted var password: String = ""
    
    override init() {
        super.init()
    }
    
    init(name: String) {
        self.name = name
        super.init()
    }
}

class Project: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var name: String
    @Persisted var root: String
    @Persisted var host: Host?
    
    override init() {
        super.init()
    }
    
    func isValid() -> Bool {
        return name.count > 0 && root.count > 0 && host != nil
    }

}
