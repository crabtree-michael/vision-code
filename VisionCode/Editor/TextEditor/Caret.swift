//
//  Caret.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/30/24.
//

import Foundation
import UIKit

class Caret: UIView {
    var blinkDuration: TimeInterval = 0.36
    var isBlinking = false

    func startBlinking() {
        isBlinking = true
        blink()
    }

    func stopBlinking() {
        isBlinking = false
    }

    private func blink() {
        UIView.animate(withDuration: blinkDuration, animations: {
            self.alpha = self.alpha > 0.25 ? 0.25 : 1
        }) { _ in
            if self.isBlinking {
                self.blink()
            } else {
                self.alpha = 1
            }
        }
    }
}
