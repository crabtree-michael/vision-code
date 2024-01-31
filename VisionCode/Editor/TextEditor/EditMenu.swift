//
//  EditMenu.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/31/24.
//

import Foundation
import UIKit

class EditMenu: UIView {
    let cutButton = UIButton()
    let pasteButton = UIButton()
    let copyButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .darkGray
        self.layer.cornerRadius = 10
        
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.5
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 1
        self.layer.shadowOffset = CGSize(width: 1, height: 1)
       
        copyButton.tintColor = .white
        copyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        copyButton.frame = CGRect(x: 4, y: 0, width: 25, height: 25)
        self.addSubview(copyButton)
        
       
        pasteButton.tintColor = .white
        pasteButton.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        pasteButton.frame = CGRect(x: 34, y: -1, width: 25, height: 25)
        self.addSubview(pasteButton)
        
        
        cutButton.tintColor = .white
        cutButton.setImage(UIImage(systemName: "scissors"), for: .normal)
        cutButton.frame = CGRect(x: 64, y: 0, width: 25, height: 25)
        self.addSubview(cutButton)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
}
