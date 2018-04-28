//
//  Item.swift
//  HGRippleRadarView
//
//  Created by Hamza Ghazouani on 27/01/2018.
//

import UIKit


/// Item object
public class Item {
    
    /// The unique key of the object
    public let uniqueKey: String
    /// The value of the object
    public let value: Any
    
    public var distance: Double?
    
    public var angle: Double?
    
    public var radarPosition: (circleIndex: Int, originIndex: Int) = (0, 0)
    
    convenience init(uniqueKey: String, value: Any, distance: Double, angle: Double) {
        self.init(uniqueKey: uniqueKey, value: value)
        self.distance = distance
        self.angle = angle
    }
    
    /// A new item initialized with the unique key and value
    ///
    /// - Parameters:
    ///   - uniqueKey: the key of the object, must be unique
    ///   - value: the value of the objet
    public init(uniqueKey: String, value: Any) {
        self.uniqueKey = uniqueKey
        self.value = value
    }
    
}

extension Item {
    
    // Private Methods
    
    private func calculatePosition() {
        let circleIndex = 1
        let positionIndex = 3
        radarPosition = (circleIndex, positionIndex)
    }
    
}

extension Item: Equatable {
    
    public static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.uniqueKey == rhs.uniqueKey
    }
    
}
