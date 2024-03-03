//
//  TabWidth.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/20/24.
//

import Foundation

enum TabSpacing {
    case tab
    case space
    
    var description: String {
        switch(self) {
        case .space:
            return "space"
        case .tab:
            return "tab"
        }
    }
}

struct TabWidth: Equatable, Hashable, Identifiable {
    let width: Int
    let spacing:TabSpacing
    
    var id: TabWidth {
        return self
    }
    
    var description: String {
        let spacingDescription = spacing.description
        
        // TODO: Support more tab widthds
        if spacing == .tab {
            return "tab"
        }
        
        switch(width) {
        case 1:
            return "1 \(spacingDescription)"
        default:
            return "\(width) \(spacingDescription)s"
        }
    }
    
    var unit: String {
        switch(self.spacing) {
        case .tab:
            return "\t"
        case .space:
            return " "
        }
    }
    
    var tabString: String {
        switch(self.spacing) {
        case .tab:
            return "\t"
        case .space:
            var result = ""
            for _ in (0..<self.width) {
                result.append(" ")
            }
            return result
        }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.spacing == rhs.spacing && lhs.width == rhs.width
    }
    
    static var fourTabs: TabWidth {
        return TabWidth(width: 4, spacing: .tab)
    }
    
    static var primarySet: [TabWidth] {
        return [
            TabWidth(width: 4, spacing: .tab),
            TabWidth(width: 1, spacing: .space),
            TabWidth(width: 2, spacing: .space),
            TabWidth(width: 3, spacing: .space),
            TabWidth(width: 4, spacing: .space),
            TabWidth(width: 5, spacing: .space),
            TabWidth(width: 6, spacing: .space),
        ]
    }
    
    static var supportedSpaceWidths: [Int] {
        return [1,2,3,4,5,6]
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(spacing)
    }
    
    static func estimate(from content: String) -> TabWidth {
        let regex = /\n([ \t]+)\S/
        let matches = content.matches(of: regex)
        var tabCount: Int = 0
        for match in matches {
            if match.output.1.contains(where: { c in
                c == "\t"
            }) {
                tabCount += 1
            }
        }
        if tabCount > matches.count/2 {
            return .fourTabs
        }
        
        var minimumSpaces: Int = matches.first?.output.1.count ?? 4
        for match in matches {
            minimumSpaces = min(match.output.1.count, minimumSpaces)
        }
        
        if minimumSpaces <= 2 {
            return TabWidth(width: 2, spacing: .space)
        }
        
        return TabWidth(width: 4, spacing: .space)
    }
}
