//
//  GutterView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/29/24.
//

import Foundation
import UIKit

class GutterView: UIView {
    var lineHeight: CGFloat = 25
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ rect: CGRect) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]
        
        var number = 1
        var height:CGFloat = 0
        while height < rect.height {
            let line = "\(number)"
            let size = line.size(withAttributes: attributes)
            
            let drawRect = CGRect(x: rect.origin.x, y: height, width: rect.width - 2, height: size.height)
            height = height + lineHeight
            line.draw(in: drawRect, withAttributes: attributes)
            number += 1
        }

        super.draw(rect)
    }
}
