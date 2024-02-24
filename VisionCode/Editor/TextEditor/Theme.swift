//
//  Theme.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/3/24.
//

import Foundation
import UIKit

class Theme {
    private let map:[String: UIColor]
    
    init(name: String) throws {
        guard let path = Bundle.main.path(forResource: name, ofType: "json") else {
            throw CommonError.objectNotFound
        }
        
        let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
        
        guard let jsonResult = jsonResult as? Dictionary<String, String> else {
            throw CommonError.unparsable
        }
        
        var colorMap: [String: UIColor] = [:]
        for (key, value) in jsonResult {
            let r, g, b: CGFloat
            let start = value.index(value.startIndex, offsetBy: 1)
            let hexColor = String(value[start...])
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat(hexNumber & 0x0000ff) / 255
                colorMap[key] = UIColor(red: r, green: g, blue: b, alpha: 1.0)
            }
        }
            
        self.map = colorMap
    }
    
    func color(forHighlight str: String) -> UIColor? {
        return self.map[str]
    }
    
    func primaryColor() -> UIColor? {
        return self.map["primary"]
    }
    
    func backgroundColor() -> UIColor? {
        return self.map["background"]
    }
}
