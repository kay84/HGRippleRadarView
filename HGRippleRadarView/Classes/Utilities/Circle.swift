//
//  Circle.swift
//  HGRippleRadarView
//
//  Created by H. Eren ÇELİK on 28.04.2018.
//

import Foundation

public let circleDefaultItemRadius: CGFloat = 10
public let circleDefaultPaddingBetweenItems: CGFloat = 8

public class Circle {
    
    var name: String = "Circle"
    
    var itemRadius: CGFloat = circleDefaultItemRadius
    var paddingBetweenItems: CGFloat = circleDefaultPaddingBetweenItems
    
    var origin = CGPoint.zero
    var radius: CGFloat = 0
    
    let distanceRange: ClosedRange<Double>?
    
    private(set) var allPoints: [CGPoint] = []
    private(set) var availablePoints: [CGPoint] = []
    
    private(set) var itemViews: [ItemView] = []
    
    private let model = CircleModel()
    
    convenience init(name: String, itemRadius: CGFloat = circleDefaultItemRadius, paddingBetweenItems: CGFloat = circleDefaultPaddingBetweenItems, origin: CGPoint, radius: CGFloat, distanceRange: ClosedRange<Double>) {
        self.init(itemRadius: itemRadius, paddingBetweenItems: paddingBetweenItems, origin: origin, radius: radius, distanceRange: distanceRange)
        self.name = name
    }
    
    public init(itemRadius: CGFloat = circleDefaultItemRadius, paddingBetweenItems: CGFloat = circleDefaultPaddingBetweenItems, origin: CGPoint, radius: CGFloat, distanceRange: ClosedRange<Double>) {
        assert(radius >= 0, NSLocalizedString("Illegal radius value", comment: ""))
        self.itemRadius = itemRadius
        self.paddingBetweenItems = paddingBetweenItems
        self.origin = origin
        self.radius = radius
        self.distanceRange = distanceRange
        calculatePositions()
    }
    
    public func originIndex(forItem item: Item) -> Int? {
        guard let angle = item.angle else { return nil }
        let point = Geometry.point(in: CGFloat(angle), of: self)
        var originIndex: Int?
        var distance: CGFloat = .greatestFiniteMagnitude
        for (index, availablePoint) in availablePoints.enumerated() {
            let d = hypot(point.x - availablePoint.x, point.y - availablePoint.y)
            if d < distance {
                distance = d
                originIndex = index
            }
        }
        return originIndex
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
    
    public func remove(itemView: ItemView?) {
        guard let itemView = itemView else { return }
        if let itemViewIndex = itemViews.index(of: itemView) {
            let success = self.remove(item: itemView.item)
            if success {
                let removedItemView = itemViews.remove(at: itemViewIndex)
                availablePoints.append(removedItemView.view.center)
            }
        }
        
    }
    
    public func add(itemView: ItemView?, at originIndex: Int) {
        guard let itemView = itemView else { return }
        let item = itemView.item
        if let distanceRange = distanceRange {
            guard let distance = item.distance, distanceRange.contains(distance) else {
                print("This item is not belong to this circle")
                return
            }
        }
        let result = model.add(item)
        if result {
            itemViews.append(itemView)
            if originIndex < 0 || originIndex > availablePoints.count { return }
            availablePoints.remove(at: originIndex)
        }
    }
    
    public func clear() {
        model.clear()
        itemViews.removeAll()
    }
    
}

extension Circle {
    
    // Private Methods
    
    private func calculatePositions() {
        // we calculate the capacity using: (2π * r1 / 2 * r2) ; r2 = (itemRadius + padding/2)
        let capacity = (radius * CGFloat.pi) / (itemRadius + paddingBetweenItems/2)
        for index in 0 ..< Int(capacity) {
            let angle = ((CGFloat(index) * 2 * CGFloat.pi) / CGFloat(capacity))
            let itemOrigin = Geometry.point(in: angle, of: self)
            allPoints.append(itemOrigin)
            availablePoints.append(itemOrigin)
        }
    }
 
    @discardableResult private func remove(item: Item?) -> Bool {
        guard let item = item else { return false }
        let result = model.remove(item)
        return result
    }
    
}
