//
//  RadarView.swift
//  HGNearbyUsers_Example
//
//  Created by Hamza Ghazouani on 25/01/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit


/// A radar view with ripple animation
@IBDesignable
final public class RadarView: RippleView {
    
    // MARK: public properties
    
    /// the maximum number of items that can be shown in the radar view, if you use more, some layers will overlaying other layers
    public var radarCapacity: Int {
        var capacity = 0
        circles.forEach { capacity += $0.allPoints.count }
        return capacity
    }
    
    /// The padding between items, the default value is 10
    @IBInspectable public var paddingBetweenItems: CGFloat = 10 {
        didSet {
            redrawItems()
        }
    }
    
    /// the background color of items, by default is turquoise
    @IBInspectable public var itemBackgroundColor = UIColor.turquoise
    
    /// The bounds rectangle, which describes the view’s location and size in its own coordinate system.
    public override var bounds: CGRect {
        didSet {
            // the sublyers are based in the view size, so if the view change the size, we should redraw sublyers
            let viewRadius = min(bounds.midX, bounds.midY)
            minimumCircleRadius = viewRadius > 120 ? 60 : diskRadius + 15
            redrawItems()
        }
    }
    
    /// The frame rectangle, which describes the view’s location and size in its superview’s coordinate system.
    public override var frame: CGRect {
        didSet {
            // the sublyers are based in the view size, so if the view change the size, we should redraw sublyers
            let viewRadius = min(bounds.midX, bounds.midY)
            minimumCircleRadius = viewRadius > 120 ? 60 : diskRadius + 15
            redrawItems()
        }
    }
    
    /// The delegate of the radar view
    public weak var delegate: RadarViewDelegate?
    
    /// The data source of the radar view
    public weak var dataSource: RadarViewDataSource?
    
    /// The current selected item
    public var selectedItem: Item? {
        return currentItemView?.item
    }
    
    // MARK: private properties
    
    /// layer to remove after hidden animation
    private var viewToRemove: UIView?
    
    /// the preferable radius of an item
    private var itemRadius: CGFloat {
        return paddingBetweenCircles / 3
    }
    
    private var currentItemView: ItemView? {
        didSet {
            if oldValue != nil && currentItemView != nil {
                delegate?.radarView(radarView: self, didDeselect: oldValue!.item)
            }
            else if oldValue != nil && currentItemView == nil {
                delegate?.radarView(radarView: self, didDeselectAllItems: oldValue!.item)
            }
            if currentItemView != nil {
                delegate?.radarView(radarView: self, didSelect: currentItemView!.item)
            }
        }
    }
    
    
    // MARK: View Life Cycle
    
    override func setup() {
        paddingBetweenCircles = 40
        let viewRadius = min(bounds.midX, bounds.midY)
        minimumCircleRadius = viewRadius > 120 ? 60 : diskRadius + 15
        
        super.setup()
    }
    
    override func redrawCircles() {
        super.redrawCircles()
        redrawItems()
    }
    
    private func redrawItems() {
        circles.forEach { circle in
            circle.clear()
            circle.itemViews.forEach { itemView in
                let view = itemView.view
                view.layer.removeAllAnimations()
                view.removeFromSuperview()
                add(item: itemView.item, using: nil)
            }
        }
    }
    
    // MARK: Utilities methods
    
    /// Add item layer to radar view
    ///
    /// - Parameters:
    ///   - item: item to add to the radar view
    ///   - animation: the animation used to show the item layer
    private func add(item: Item, using animation: CAAnimation? = Animation.transform()) {
        
        let circlesCount = circles.count
        
        let circleIndex = item.preferredCircleIndex(in: circlesCount)
        
        let circle = circles[circleIndex]
        
        if circle.availablePoints.count == 0 {
            print("There is no available room for item in circle \(circle.name)")
            return
        }
        
        circle.add(item: item)

        guard let origin = circle.origin(forItem: item) else { return }
        
        let preferredSize = CGSize(width: itemRadius*2, height: itemRadius*2)
        let customView = dataSource?.radarView(radarView: self, viewFor: item, preferredSize: preferredSize)
        let itemView = addItem(view: customView, with: origin, and: animation)
        let itemLayer = ItemView(view: itemView, item: item)
        self.addSubview(itemView)
        
        circle.itemViews.append(itemLayer)
        
    }
    
    private func addItem(view: UIView?, with origin: CGPoint, and animation: CAAnimation?) -> UIView {
        let itemView = view ?? Drawer.diskView(radius: itemRadius, origin: origin, color: itemBackgroundColor)
        itemView.center = origin
        itemView.isUserInteractionEnabled = false
        
        guard let anim = animation else { return itemView }
        let hide = Animation.transform(to: 0.0)
        hide.duration = anim.beginTime - CACurrentMediaTime()
        itemView.layer.add(hide, forKey: nil)
        itemView.layer.add(anim, forKey: nil)
        
        return itemView
    }
    
    /// Remove layer from radar view
    ///
    /// - Parameter layer: the layer to remove
    private func removeWithAnimation(view: UIView) {
        viewToRemove = view
        let hideAnimation = Animation.hide()
        hideAnimation.delegate = self
        
        view.layer.add(hideAnimation, forKey: nil)
    }
    
    // MARK: manage user interaction
    
    /// Tells this object that one or more new touches occurred in a view or window.
    ///
    /// - Parameters:
    ///   - touches: A set of UITouch instances that represent the touches for the starting phase of the event
    ///   - event: The event to which the touches belong.
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        guard let point = touch?.location(in: self) else { return }
        var index = -1
        var circle: Circle?
        for i in 0..<circles.count {
            circle = circles[i]
            if let i = circle?.itemViews.index(where: { return $0.view.frame.contains(point) }) {
                index = i
                return
            }
        }
        if let circle = circle, index >= 0, index < circle.itemViews.count {
            let item = circle.itemViews[index]
            if item === currentItemView { return }
            currentItemView = item
            let itemView = item.view
            self.bringSubview(toFront: itemView)
            let animation = Animation.opacity(from: 0.3, to: 1.0)
            itemView.layer.add(animation, forKey: "opacity")
        } else {
            currentItemView = nil
        }
    }
}

extension RadarView: CAAnimationDelegate {
    
    /// Tells the delegate the animation has ended.
    ///
    /// - Parameters:
    ///   - anim: The CAAnimation object that has ended.
    ///   - flag: A flag indicating whether the animation has completed by reaching the end of its duration.
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        viewToRemove?.removeFromSuperview()
        viewToRemove = nil
    }
}

// MARK: public methods
extension RadarView {
    /// Add a list of items to the radar view
    ///
    /// - Parameters:
    ///   - items: the items to add to the radar view
    ///   - animation: the animation used to show  items layers
    public func add(items: [Item], using animation: CAAnimation = Animation.transform()) {
        for index in 0 ..< items.count {
            animation.beginTime = CACurrentMediaTime() + CFTimeInterval(animation.duration/2 * Double(index))
            self.add(item: items[index], using: animation)
        }
    }
    
    /// Add item randomly in the radar view
    ///
    /// - Parameters:
    ///   - item: the item to add to the radar view
    ///   - animation: the animation used to show  items layers
    public func add(item: Item, using animation: CAAnimation = Animation.transform()) {
        add(item: item, using: animation)
    }
    
    /// Remove item layer from the radar view
    ///
    /// - Parameter item: the item to remove from Radar View
    public func remove(item: Item) {
        let circleIndex = item.preferredCircleIndex(in: circles.count)
        let circle = circles[circleIndex]
        guard let itemView = circle.itemView(forItem: item) else { return }
        guard let itemViewIndex = circle.itemViewIndex(forItem: item) else { return }
        removeWithAnimation(view: itemView.view)
        circle.itemViews.remove(at: itemViewIndex)
    }
    
    /// Returns the view of the item
    ///
    /// - Parameter item: the item
    /// - Returns: the layer of the item with the index
    public func view(for item: Item) -> UIView? {
        let circleIndex = item.preferredCircleIndex(in: circles.count)
        let circle = circles[circleIndex]
        guard let itemView = circle.itemView(forItem: item) else { return nil }
        return itemView.view
    }
    
}

extension Drawer {
    /// Creates a disk layer
    ///
    /// - Parameters:
    ///   - radius: the radius of the disk
    ///   - origin: the origin of the disk
    ///   - color: the color of the disk
    /// - Returns: a disk layer
    static func diskView(radius: CGFloat, origin: CGPoint, color: UIColor) -> UIView {
        let frame = CGRect(x: 0, y: 0, width: radius*2, height: radius*2)
        let view = UIView(frame: frame)
        view.center = origin
        view.layer.cornerRadius = radius
        view.clipsToBounds = true
        view.backgroundColor = color
        return view
    }}
