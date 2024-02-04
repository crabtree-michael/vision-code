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
        guard let path = Bundle.main.path(forResource: "theme", ofType: "json") else {
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
        let name = highlightNameToThemeName(str)
        return self.map[name]
    }
    
    private func highlightNameToThemeName(_ str: String) -> String {
        var result = str
        if let firstChar = result.first {
            result.replaceSubrange(result.startIndex...result.startIndex, with: String(firstChar).uppercased())
        }
        result = "TS" + result
        var i = result.startIndex
        while i < result.endIndex {
            if result[i] == "." {
                let nextIndex = result.index(after: i)
                if nextIndex < result.endIndex {
                    let nextChar = result[nextIndex]
                    result.replaceSubrange(i...nextIndex, with: String(nextChar).uppercased())
                    i = result.index(i, offsetBy: 2, limitedBy: result.endIndex) ?? result.endIndex
                } else {
                    result.remove(at: i)
                    i = nextIndex
                }
            } else {
                i = result.index(after: i)
            }
        }
        return result
    }
}
