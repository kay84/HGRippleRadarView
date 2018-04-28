//
//  CircleModel.swift
//  HGRippleRadarView
//
//  Created by H. Eren ÇELİK on 28.04.2018.
//

import Foundation

class CircleModel {
    
    var items: [Item] = []
    
    @discardableResult func add(_ item: Item) -> Bool {
        if items.contains(item) { return false }
        items.append(item)
        //print("Added")
        return true
    }
    
    @discardableResult func remove(_ item: Item) -> Bool {
        if !items.contains(item) { return false }
        if let index = items.index(of: item) {
            return self.remove(index)
        }
        return false
    }
    
    @discardableResult func remove(_ index: Int) -> Bool {
        if index < 0 || index >= items.count { return false }
        items.remove(at: index)
        //print("Removed")
        return true
    }
    
    func clear() {
        items.removeAll()
    }
    
}
