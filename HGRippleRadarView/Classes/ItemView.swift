//
//  ItemLayer.swift
//  HGRippleRadarView
//
//  Created by Hamza Ghazouani on 27/01/2018.
//

import UIKit

class ItemView {
    
    let view: UIView
    
    let item: Item
    
    init(view: UIView, item: Item) {
        self.view = view
        self.item = item
    }
    
}

extension ItemView: Equatable {
    
    public static func ==(lhs: ItemView, rhs: ItemView) -> Bool {
        return lhs.item.uniqueKey == rhs.item.uniqueKey
    }
    
}
