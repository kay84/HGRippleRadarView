//
//  RadarViewProtocol.swift
//  HGNearbyUsers_Example
//
//  Created by Hamza Ghazouani on 26/01/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

public protocol RadarViewDataSource: class {
    
    func radarView(radarView: RadarView, viewFor item: Item, preferredSize: CGSize) -> UIView
    
}

public protocol RadarViewDelegate: class {
    
    func radarView(radarView: RadarView, didSelect item: Item)
    
    func radarView(radarView: RadarView, didDeselect item: Item)
    
    func radarView(radarView: RadarView, didDeselectAllItems lastSelectedItem: Item)

}
