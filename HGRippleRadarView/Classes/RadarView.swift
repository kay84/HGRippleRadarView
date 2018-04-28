//
//  RadarView.swift
//  HGNearbyUsers_Example
//
//  Created by Hamza Ghazouani on 23/01/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit


/// A view with ripple animation

@IBDesignable
public final class RadarView: UIView {
    
    /// the maximum number of items that can be shown in the radar view, if you use more, some layers will overlaying other layers
    public var radarCapacity: Int {
        var capacity = 0
        circles.forEach { capacity += $0.allPoints.count }
        return capacity
    }
    
    /// The padding between items, the default value is 10
    @IBInspectable public var paddingBetweenItems: CGFloat = circleDefaultPaddingBetweenItems {
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
        return paddingBetweenCircles / 4
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
    
    // MARK: Private Properties
    
    /// the center circle used for the scale animation
    private var centerAnimatedLayer: CAShapeLayer!
    
    /// the center disk point
    private var diskLayer: CAShapeLayer!
    
    /// The duration to animate the central disk
    private var centerAnimationDuration: CFTimeInterval {
        return CFTimeInterval(animationDuration) * 0.75
    }
    
    /// The duration to animate one circle
    private var circleAnimationDuration: CFTimeInterval {
        if circleLayers.count ==  0 {
            return CFTimeInterval(animationDuration)
        }
        return CFTimeInterval(animationDuration) / CFTimeInterval(circleLayers.count)
    }
    
    /// The timer used to start / stop circles animation
    private var circlesAnimationTimer: Timer?
    
    /// The timer used to start / stop disk animation
    private var diskAnimationTimer: Timer?
    
    // MARK: Internal properties
    
    /// The maximum possible radius of circle
    var maxCircleRadius: CGFloat {
        if numberOfCircles == 0 {
            return min(bounds.midX, bounds.midY)
        }
        return (circlesPadding * CGFloat(numberOfCircles - 1) + minimumCircleRadius)
    }
    
    /// the circles surrounding the disk
    var circleLayers = [CAShapeLayer]()
    var circles = [Circle]()
    
    /// The padding between circles
    var circlesPadding: CGFloat {
        if paddingBetweenCircles != -1 {
            return paddingBetweenCircles
        }
        let availableRadius = min(bounds.width, bounds.height)/2 - (minimumCircleRadius)
        return  availableRadius / CGFloat(numberOfCircles)
    }
    
    // MARK: Public Properties
    
    @IBInspectable public var minDistance: Double = 0 {
        didSet {
            redrawDisks()
            redrawCircles()
        }
    }
    
    @IBInspectable public var maxDistance: Double = 6000 {
        didSet {
            redrawDisks()
            redrawCircles()
        }
    }
    
    /// The radius of the disk in the view center, the default value is 5
    @IBInspectable public var diskRadius: CGFloat = 5 {
        didSet {
            redrawDisks()
            redrawCircles()
        }
    }
    
    /// The color of the disk in the view center, the default value is ripplePink color
    @IBInspectable public var diskColor: UIColor = .ripplePink {
        didSet {
            diskLayer.fillColor = diskColor.cgColor
            centerAnimatedLayer.fillColor = diskColor.cgColor
        }
    }
    
    /// The number of circles to draw around the disk, the default value is 3, if the forcedMaximumCircleRadius is used the number of drawn circles could be less than numberOfCircles
    @IBInspectable public var numberOfCircles: Int = 4 {
        didSet {
            redrawCircles()
        }
    }
    
    /// The padding between circles
    @IBInspectable public var paddingBetweenCircles: CGFloat = -1 {
        didSet {
            redrawCircles()
        }
    }
    
    /// The color of the off status of the circle, used for animation
    @IBInspectable public var circleOffColor: UIColor = .rippleDark {
        didSet {
            circleLayers.forEach {
                $0.strokeColor = circleOffColor.cgColor
            }
        }
    }
    
    /// The color of the on status of the circle, used for animation
    @IBInspectable public var circleOnColor: UIColor = .rippleWhite
    
    /// The minimum radius of circles, used to make space between the disk and the first circle, the radius must be grather than 5px , because if not the first circle will not be shown, the default value is 10, it's recommanded to use a value grather than the disk radius if you would like to show circles outside disk
    @IBInspectable public var minimumCircleRadius: CGFloat = 10 {
        didSet {
            if minimumCircleRadius < 5 {
                minimumCircleRadius = 5
            }
            redrawCircles()
        }
    }
    
    /// The duration of the animation, the default value is 0.9
    @IBInspectable public var animationDuration: CGFloat = 0.9 {
        didSet {
            stopAnimation()
            startAnimation()
        }
    }
    
    
    // MARK: init methods
    
    /// Initializes and returns a newly allocated view object with the specified frame rectangle.
    ///
    /// - Parameter frame: The frame rectangle for the view, measured in points.
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    /// Initializes and returns a newly allocated view object from data in a given unarchiver.
    ///
    /// - Parameter aDecoder: An unarchiver object.
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        paddingBetweenCircles = 40
        let viewRadius = min(bounds.midX, bounds.midY)
        minimumCircleRadius = viewRadius > 120 ? 60 : diskRadius + 15
        drawSublayers()
        animateSublayers()
    }
    
    // MARK: Drawing methods
    
    /// Calculate the radius of a circle by using its index
    ///
    /// - Parameter index: the index of the circle
    /// - Returns: the radius of the circle
    func radiusOfCircle(at index: Int) -> CGFloat {
        return (circlesPadding * CGFloat(index)) + minimumCircleRadius
    }
    
    /// Lays out subviews.
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        diskLayer.position = bounds.center
        centerAnimatedLayer.position = bounds.center
        circleLayers.forEach {
            $0.position = bounds.center
        }
    }
    
    /// Draws disks and circles
    private func drawSublayers() {
       drawDisks()
       redrawCircles()
    }
    
    /// Draw central disk and the disk for the central animation
    private func drawDisks() {
        diskLayer = Drawer.diskLayer(radius: diskRadius, origin: bounds.center, color: diskColor.cgColor)
        layer.insertSublayer(diskLayer, at: 0)
        
        centerAnimatedLayer = Drawer.diskLayer(radius: diskRadius, origin: bounds.center, color: diskColor.cgColor)
        centerAnimatedLayer.opacity = 0.3
        layer.addSublayer(centerAnimatedLayer)
    }
    
    /// Redraws disks by deleting the old ones and drawing a new ones, called for example when the radius changed
    private func redrawDisks() {
        diskLayer.removeFromSuperlayer()
        centerAnimatedLayer.removeFromSuperlayer()
        
        drawDisks()
    }

    /// Redraws circles by deleting old ones and drawing new ones, this method is called, for example, when the number of circles changed
    func redrawCircles() {
        circleLayers.forEach {
            $0.removeFromSuperlayer()
        }
        circleLayers.removeAll()
        circles.removeAll()
        for i in 0 ..< numberOfCircles {
            drawCircle(with: i)
        }
    }
    
    /// Draws the circle by using the index to calculate the radius
    ///
    /// - Parameter index: the index of the circle
    private func drawCircle(with index: Int) {
        let distanceInterval: Double = (maxDistance - minDistance) / Double(numberOfCircles)
        let minDistanceForCircle = index == 0 ? minDistance : Double(index) * distanceInterval
        let maxDistanceForCircle = index == numberOfCircles - 1 ? maxDistance : Double(index + 1) * distanceInterval
        let radius = radiusOfCircle(at: index)
        if radius > maxCircleRadius { return }
        let origin = bounds.center
        let circleLayer = Drawer.circleLayer(radius: radius, origin: origin, color: circleOffColor.cgColor)
        circleLayer.lineWidth = 2.0
        circleLayers.append(circleLayer)
        self.layer.addSublayer(circleLayer)
        circles.append(Circle(name: "C\(index + 1)", itemRadius: itemRadius, paddingBetweenItems: paddingBetweenItems, origin: origin, radius: radius, distanceRange: (minDistanceForCircle...maxDistanceForCircle)))
    }
    
    // MARK: Animation methods
    
    /// Add animation to central disk and the surrounding circles 
    private func animateSublayers() {
        animateCentralDisk()
        animateCircles()
        startAnimation()
    }
    
    /// Animates the central disk by changing the opacitiy and the scale
    @objc private func animateCentralDisk() {
        let maxScale = maxCircleRadius / diskRadius
        let scaleAnimation = Animation.transform(to: maxScale)
        let alphaAnimation = Animation.opacity(from: 0.3, to: 0.0)
        let groupAnimation = Animation.group(animations: scaleAnimation, alphaAnimation, duration: centerAnimationDuration)
        centerAnimatedLayer.add(groupAnimation, forKey: nil)
        self.layer.addSublayer(centerAnimatedLayer)
    }
    
    /// Animates circles by changing color from off to on color
    @objc private func animateCircles() {
        for index in 0 ..< circleLayers.count {
            let colorAnimation = Animation.color(from: circleOffColor.cgColor, to: circleOnColor.cgColor)
            colorAnimation.duration = circleAnimationDuration
            colorAnimation.autoreverses = true
            colorAnimation.beginTime = CACurrentMediaTime() + CFTimeInterval(circleAnimationDuration * Double(index))
            circleLayers[index].add(colorAnimation, forKey: "strokeColor")
        }
    }
}

extension RadarView {
    
    
    // MARK: View Life Cycle
    
    private func redrawItems() {
        circles.forEach { circle in
            let itemViews = Array(circle.itemViews)
            circle.clear()
            itemViews.forEach { itemView in
                let view = itemView.view
                view.layer.removeAllAnimations()
                view.removeFromSuperview()
                add(itemView.item, using: nil)
            }
        }
    }
    
    // MARK: Utilities methods
    
    private func circleIndex(forItem item: Item?) -> Int? {
        guard let item = item else { return nil }
        for (index, circle) in circles.enumerated() {
            if let range = circle.distanceRange, let distance = item.distance, range.contains(distance) {
                return index
            }
        }
        return nil
    }
    
    /// Add item layer to radar view
    ///
    /// - Parameters:
    ///   - item: item to add to the radar view
    ///   - animation: the animation used to show the item layer
    private func add(_ item: Item, using animation: CAAnimation? = Animation.transform()) {
        
        guard let index = circleIndex(forItem: item) else { return }
        
        let circle = circles[index]
        
        if circle.availablePoints.count == 0 {
            print("There is no available room for item in circle \(circle.name)")
            return
        }
        
        guard let originIndex = circle.originIndex(forItem: item) else { return }
        if originIndex < 0 || originIndex > circle.availablePoints.count { return }
        
        let origin = circle.availablePoints[originIndex]
        
        let preferredSize = CGSize(width: itemRadius*2, height: itemRadius*2)
        let customView = dataSource?.radarView(radarView: self, viewFor: item, preferredSize: preferredSize)
        
        let view = addItem(view: customView, with: origin, and: animation)
        
        let itemView = ItemView(view: view, item: item)
        
        self.addSubview(view)
        
        circle.add(itemView: itemView, at: originIndex)
        
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
    
    /// Start the ripple animation
    public func startAnimation() {
        layer.removeAllAnimations()
        circlesAnimationTimer?.invalidate()
        diskAnimationTimer?.invalidate()
        let timeInterval = CFTimeInterval(animationDuration) + circleAnimationDuration
        circlesAnimationTimer =  Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(animateCircles), userInfo: nil, repeats: true)
        diskAnimationTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(animateCentralDisk), userInfo: nil, repeats: true)
    }
    
    /// Stop the ripple animation
    public func stopAnimation() {
        layer.removeAllAnimations()
        circlesAnimationTimer?.invalidate()
        diskAnimationTimer?.invalidate()
    }
    
    /// Add a list of items to the radar view
    ///
    /// - Parameters:
    ///   - items: the items to add to the radar view
    ///   - animation: the animation used to show  items layers
    public func add(items: [Item], using animation: CAAnimation = Animation.transform()) {
        for index in 0 ..< items.count {
            animation.beginTime = CACurrentMediaTime() + CFTimeInterval(animation.duration/2 * Double(index))
            self.add(items[index], using: animation)
        }
    }
    
    /// Add item randomly in the radar view
    ///
    /// - Parameters:
    ///   - item: the item to add to the radar view
    ///   - animation: the animation used to show  items layers
    public func add(item: Item, using animation: CAAnimation = Animation.transform()) {
        self.add(item, using: animation)
    }
    
    /// Remove item layer from the radar view
    ///
    /// - Parameter item: the item to remove from Radar View
    public func remove(item: Item) {
        guard let index = circleIndex(forItem: item) else { return }
        let circle = circles[index]
        guard let itemView = circle.itemView(forItem: item) else { return }
        circle.remove(itemView: itemView)
        let view = itemView.view
        viewToRemove = view
        removeWithAnimation(view: view)
    }
    
    /// Returns the view of the item
    ///
    /// - Parameter item: the item
    /// - Returns: the layer of the item with the index
    public func view(for item: Item) -> UIView? {
        guard let index = circleIndex(forItem: item) else { return nil }
        let circle = circles[index]
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
    }
    
}







