//
//  File.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/28/24.
//

import Foundation
import UIKit

class TextLayoutFragmentView: UIView {
    var layoutFragment: NSTextLayoutFragment?
    
    init(fragment: NSTextLayoutFragment) {
        self.layoutFragment = fragment
        super.init(frame: fragment.layoutFragmentFrame)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        self.layoutFragment = nil
        super.init(coder: coder)
    }
    
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        
        self.layoutFragment?.draw(at: .zero, in: ctx)
    }
    
    func change(to fragment: NSTextLayoutFragment) {
        self.layoutFragment = fragment
        self.frame = layoutFragment!.renderingSurfaceBounds
        self.setNeedsDisplay()
    }
}
