//
//  Circle.swift
//  HGRippleRadarView
//
//  Created by H. Eren ÇELİK on 28.04.2018.
//

import Foundation

public class Circle {
    
    var name: String = "Circle"
    
    var origin = CGPoint.zero
    var radius: CGFloat = 0
    
    private(set) var allPoints: [CGPoint] = []
    private(set) var availablePoints: [CGPoint] = []
    
    internal(set) var itemViews: [ItemView] = []
    
    private let model = CircleModel()
    
    convenience init(name: String, origin: CGPoint, radius: CGFloat) {
        self.init(origin: origin, radius: radius)
        self.name = name
    }
    
    public init(origin: CGPoint, radius: CGFloat) {
        assert(radius >= 0, NSLocalizedString("Illegal radius value", comment: ""))
        self.origin = origin
        self.radius = radius
        findPossiblePositions()
    }
    
    public func origin(forItem item: Item) -> CGPoint? {
        let index = item.preferredIndex(in: self)
        if index < 0 || index >= availablePoints.count { return nil }
        return availablePoints[index]
    }
    
    func itemView(forItem item: Item) -> ItemView? {
        return itemViews.first(where: { $0.item == item })
    }
    
    func itemViewIndex(forItem item: Item) -> Int? {
        for (index, itemView) in itemViews.enumerated() {
            if itemView.item == item {
                return index
            }
        }
        return nil
    }
    
    public func remove(item: Item?) {
        guard let item = item else { return }
        let result = model.remove(item)
        if result {
            print("Removed")
        }
    }
    
    public func add(item: Item?) {
        guard let item = item else { return }
        let result = model.add(item)
        if result {
            print("Added")
            availablePoints.remove(at: 1)
        }
    }
    
    public func clear() {
        model.clear()
        itemViews.removeAll()
    }
    
}

extension Circle {
    
    // Private Methods
    
    private func findPossiblePositions() {
        // we calculate the capacity using: (2π * r1 / 2 * r2) ; r2 = (itemRadius + padding/2)
        //let capacity = (radius * CGFloat.pi) / (itemRadius + paddingBetweenItems/2)
        let capacity = (radius * CGFloat.pi) / (4 + 8/2)
        for index in 0 ..< Int(capacity) {
            let angle = ((CGFloat(index) * 2 * CGFloat.pi) / CGFloat(capacity))
            let itemOrigin = Geometry.point(in: angle, of: self)
            allPoints.append(itemOrigin)
            availablePoints.append(itemOrigin)
        }
    }
    
}
