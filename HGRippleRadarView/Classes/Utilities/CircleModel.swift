//
//  CircleModel.swift
//  HGRippleRadarView
//
//  Created by H. Eren ÇELİK on 28.04.2018.
//

import Foundation

class CircleModel {
    
    var items: [Item] = []
    
    func add(_ item: Item) -> Bool {
        if items.contains(item) { return false }
        items.append(item)
        return true
    }
    
    func remove(_ item: Item) -> Bool {
        if !items.contains(item) { return false }
        if let index = items.index(of: item) {
            return remove(index)
        }
        return false
    }
    
    func remove(_ index: Int) -> Bool {
        if index < 0 || index >= items.count { return false }
        items.remove(at: index)
        return true
    }
    
    func clear() {
        items.removeAll()
    }
    
}
