//
//  Recycler.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/29/24.
//

import Foundation
import UIKit

class TextLayoutFragmentViewRecycler {
    var views = [TextLayoutFragmentView]()
    var availableViews = [TextLayoutFragmentView?]()
    
    private var fragmentAvailableIndexMap = [NSTextLayoutFragment:Int]()
    private var fragmentReuseMap = [NSTextLayoutFragment:TextLayoutFragmentView]()
    
    var requests: Float = 0
    var creations: Float = 0
    var recycles: Float = 0
    var hits: Float = 0
    
    func retrieve(for fragment: NSTextLayoutFragment) -> (TextLayoutFragmentView, Bool) {
        requests += 1
        
        if let availableView = fragmentReuseMap[fragment] {
            hits += 1
            availableView.change(to: fragment)
            fragmentReuseMap.removeValue(forKey: fragment)
            return (availableView, false)
        }
        
        if let index = fragmentAvailableIndexMap[fragment],
            let view = availableViews[index] {
            hits += 1
            availableViews[index] = nil
            view.change(to: fragment)
            return (view, false)
        }
        
        for (index, view) in availableViews.enumerated() {
            guard let view = view else {
                continue
            }
            recycles += 1
            view.change(to: fragment)
            availableViews[index] = nil
            return (view, false)
        }
        
        creations += 1
        let view = TextLayoutFragmentView(fragment: fragment)
        views.append(view)
        return (view, true)
    }
    
    func prepareForReuse() {
        requests = 0
        creations = 0
        recycles = 0
        hits = 0
        
        fragmentAvailableIndexMap = [NSTextLayoutFragment:Int]()
        fragmentReuseMap = [NSTextLayoutFragment:TextLayoutFragmentView]()
        availableViews = []
        
        for view in views {
            guard let fragment = view.layoutFragment else {
                continue
            }
            
            availableViews.append(view)
            fragmentAvailableIndexMap[fragment] = availableViews.count - 1
        }
    }
    
    func unusedViews() -> [UIView] {
        var results = [UIView]()
        for value in self.fragmentReuseMap.values {
            results.append(value)
        }
        
        for view in self.availableViews {
            if let view = view {
                results.append(view)
            }
        }
        return results
    }
}
