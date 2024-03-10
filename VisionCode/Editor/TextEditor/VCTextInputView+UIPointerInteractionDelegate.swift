//
//  VCTextInputView+UIPointerInteractionDelegate.swift
//  VisionCode
//
//  Created by Michael Crabtree on 3/10/24.
//

import Foundation
import UIKit

extension VCTextInputView: UIPointerInteractionDelegate {
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        return UIPointerStyle(shape: .verticalBeam(length: self.lineHeight))
    }
}
