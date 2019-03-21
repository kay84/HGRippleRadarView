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
            redrawCircles()
        }
    }
    
    /// the background color of items, by default is turquoise
    @IBInspectable public var itemBackgroundColor = UIColor.turquoise
    
    /// The bounds rectangle, which describes the view’s location and size in its own coordinate system.
    public override var bounds: CGRect {
        didSet {
            // the sublyers are based in the view size, so if the view change the size, we should redraw sublyers
            redrawCircles()
        }
    }
    
    /// The frame rectangle, which describes the view’s location and size in its superview’s coordinate system.
    public override var frame: CGRect {
        didSet {
            // the sublyers are based in the view size, so if the view change the size, we should redraw sublyers
            redrawCircles()
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
        return 18.0
    }
    
    private var currentItemView: ItemView? {
        didSet {
            
            if oldValue != nil && currentItemView != nil {
                delegate?.radarView(radarView: self, didDeselect: oldValue!.item)
            } else if oldValue != nil && currentItemView == nil {
                delegate?.radarView(radarView: self, didDeselectAllItems: oldValue!.item)
            }
            
            if currentItemView != nil {
                delegate?.radarView(radarView: self, didSelect: currentItemView!.item)
            }
            
        }
    }
    
    // MARK: Private Properties
    
    private var indicator: RadarIndicatorView!
    
    /// the center circle used for the scale animation
    private var centerAnimatedLayer: CAShapeLayer!
    private var centerAnimatedTrackerLayer: CAShapeLayer!
    
    public var centerView: UIView? {
        didSet {
            redrawDisks()
            redrawCircles()
        }
    }
    
    private var centerViewAnimationDuration: CFTimeInterval {
        return 0.8
    }
    
    private var firstLayerAnimationDuration: CFTimeInterval {
        return 0.4
    }
    
    private var secondLayerAnimationDuration: CFTimeInterval {
        return 0.8
    }
    
    /// The timer used to start / stop circles animation
    private var circlesAnimationTimer: Timer?
    
    /// The timer used to start / stop disk animation
    private var diskAnimationTimer: Timer?
    
    private var minimumCircleRadius: CGFloat {
        return diskRadius + paddingBetweenCircles
    }
    
    private var impactFeedbackGenerator: Any?
    
    /// The maximum possible radius of circle
    var maxCircleRadius: CGFloat {
        if numberOfCircles == 0 {
            return min(bounds.midX, bounds.midY)
        }
        return (paddingBetweenCircles * CGFloat(numberOfCircles - 1) + minimumCircleRadius)
    }
    
    /// the circles surrounding the disk
    var circleLayers = [CAShapeLayer]()
    var circles = [Circle]()
    
    // MARK: Public Properties
    
    @IBInspectable public var minDistance: Double = 0 {
        didSet {
            redrawDisks()
            redrawCircles()
        }
    }
    
    @IBInspectable public var maxDistance: Double = 1000 {
        didSet {
            redrawDisks()
            redrawCircles()
        }
    }
    
    /// The radius of the disk in the view center, the default value is 5
    @IBInspectable public var diskRadius: CGFloat = 8 {
        didSet {
            redrawDisks()
            redrawCircles()
        }
    }
    
    /// The color of the disk in the view center, the default value is ripplePink color
    @IBInspectable public var diskColor: UIColor = .ripplePink {
        didSet {
            centerAnimatedLayer.fillColor = diskColor.cgColor
            centerAnimatedTrackerLayer.fillColor = diskColor.cgColor
        }
    }
    
    /// The number of circles to draw around the disk, the default value is 3, if the forcedMaximumCircleRadius is used the number of drawn circles could be less than numberOfCircles
    @IBInspectable public var numberOfCircles: Int = 3 {
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
        setupHapticFeedbackGenerator()
        setupIndicator()
        drawSublayers()
    }
    
    // MARK: Drawing methods
    
    /// Calculate the radius of a circle by using its index
    ///
    /// - Parameter index: the index of the circle
    /// - Returns: the radius of the circle
    func radiusOfCircle(at index: Int) -> CGFloat {
        return (paddingBetweenCircles * CGFloat(index)) + minimumCircleRadius
    }
    
    /// Lays out subviews.
    override public func layoutSubviews() {
        super.layoutSubviews()
        centerView?.center = bounds.center
        centerAnimatedLayer.position = bounds.center
        centerAnimatedTrackerLayer.position = bounds.center
        circleLayers.forEach {
            $0.position = bounds.center
        }
    }
    
    private func setupHapticFeedbackGenerator() {
        if #available(iOS 10.0, *) {
            impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        } else {
            // Fallback on earlier versions
            impactFeedbackGenerator = nil
        }
    }
    
    private func setupIndicator() {
        indicator = RadarIndicatorView(frame: self.bounds)
        indicator.alpha = 0
        indicator.indicatorColor = diskColor
        indicator.backgroundColor = .clear
        insertSubview(indicator, at: 0)
    }
    
    private func drawSublayers() {
        drawDisks()
        redrawCircles()
    }
    
    private func drawDisks() {
        if let centerView = centerView {
            centerView.center = bounds.center
            addSubview(centerView)
        }
        centerAnimatedLayer = Drawer.diskLayer(radius: diskRadius, origin: bounds.center, color: diskColor.cgColor)
        centerAnimatedLayer.opacity = 0
        layer.addSublayer(centerAnimatedLayer)
        centerAnimatedTrackerLayer = Drawer.diskLayer(radius: diskRadius, origin: bounds.center, color: diskColor.cgColor)
        centerAnimatedTrackerLayer.opacity = 0
        layer.addSublayer(centerAnimatedTrackerLayer)
    }
    
    private func redrawDisks() {
        centerView?.removeFromSuperview()
        centerAnimatedLayer.removeFromSuperlayer()
        centerAnimatedTrackerLayer.removeFromSuperlayer()
        drawDisks()
    }
    
    func redrawCircles() {
        circles.forEach { circle in
            circle.itemViews.forEach { itemView in
                let view = itemView.view
                view.layer.removeAllAnimations()
                view.removeFromSuperview()
            }
            circle.clear()
        }
        circleLayers.forEach {
            $0.removeFromSuperlayer()
        }
        circleLayers.removeAll()
        circles.removeAll()
        for i in 0 ..< numberOfCircles {
            drawCircle(with: i)
        }
        redrawItems()
    }
    
    private func drawCircle(with index: Int) {
        let distanceInterval: Double = (maxDistance - minDistance) / Double(numberOfCircles)
        let minDistanceForCircle = minDistance + Double(index) * distanceInterval
        let maxDistanceForCircle = minDistanceForCircle + distanceInterval
        if minDistanceForCircle >= maxDistanceForCircle { return }
        let radius = radiusOfCircle(at: index)
        if radius > maxCircleRadius { return }
        let origin = bounds.center
        let circleLayer = Drawer.circleLayer(radius: radius, origin: origin, color: circleOnColor.cgColor)
        circleLayer.opacity = 1
        circleLayer.lineWidth = 2.0
        circleLayers.append(circleLayer)
        self.layer.addSublayer(circleLayer)
        circles.append(Circle(name: "C\(index + 1)", itemRadius: itemRadius, paddingBetweenItems: paddingBetweenItems, origin: origin, radius: radius, distanceRange: (minDistanceForCircle...maxDistanceForCircle)))
    }
    
}

private extension RadarView {
    
    // Animation Methods
    
    func animateSublayers() {
        animateCentralDisk()
        startAnimation()
    }
    
    func playHapticIfAvailable(_ delay: TimeInterval) {
        if #available(iOS 10.0, *) {
            if let impactFeedbackGenerator = impactFeedbackGenerator as? UIImpactFeedbackGenerator {
                Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { timer in
                    impactFeedbackGenerator.prepare()
                    impactFeedbackGenerator.impactOccurred()
                }
            }
        }
    }
    
    func animateHeartBeatHaptic() {
        self.playHapticIfAvailable(0.4)
        self.playHapticIfAvailable(0.6)
    }
    
    @objc func animateCentralDisk() {
        let beginTime = CACurrentMediaTime()
        animateHeartBeatHaptic()
        if let centerView = centerView {
            let centerViewAnimation = Animation.transform(times: [0.0, 0.25, 0.5, 0.75, 1], values: [1.0, 1.05, 1.10, 1.05, 1.0], duration: centerViewAnimationDuration)
            centerViewAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            centerViewAnimation.beginTime = beginTime
            centerView.layer.add(centerViewAnimation, forKey: nil)
        }
        let scale: CGFloat = 3.8
        let scaleAnimation = Animation.transform(to: scale)
        let alphaAnimation = Animation.opacity(from: 1.0, to: 0.0)
        let groupAnimation = Animation.group(animations: scaleAnimation, alphaAnimation, duration: firstLayerAnimationDuration)
        groupAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        groupAnimation.beginTime = beginTime + 0.25
        self.layer.insertSublayer(centerAnimatedLayer, at: 0)
        centerAnimatedLayer.add(groupAnimation, forKey: nil)
        let trackerScaleAnimation = Animation.transform(to: scale + 1.2)
        let trackerAlphaAnimation = Animation.opacity(from: 1.0, to: 0.0)
        let trackerGroupAnimation = Animation.group(animations: trackerScaleAnimation, trackerAlphaAnimation, duration: secondLayerAnimationDuration)
        trackerGroupAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        trackerGroupAnimation.beginTime = groupAnimation.beginTime + 0.25
        self.layer.insertSublayer(centerAnimatedTrackerLayer, at: 1)
        centerAnimatedTrackerLayer.add(trackerGroupAnimation, forKey: nil)
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
                add(itemView.item)
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
    
    private func removeWithAnimation(view: UIView) {
        viewToRemove = view
        let hideAnimation = Animation.hide()
        hideAnimation.delegate = self
        view.layer.add(hideAnimation, forKey: "remove-item")
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        guard let point = touch?.location(in: self) else { return }
        var index = -1
        var circle: Circle?
        for i in 0..<circles.count {
            circle = circles[i]
            if let i = circle?.itemViews.index(where: { return $0.view.frame.contains(point) }) {
                index = i
                break
            }
        }
        if let circle = circle, index >= 0, index < circle.itemViews.count {
            let item = circle.itemViews[index]
            currentItemView = item
            let itemView = item.view
            self.bringSubviewToFront(itemView)
            let animation = Animation.transform(from: 1, to: 1.3)
            animation.autoreverses = true
            animation.duration = 0.1
            itemView.layer.add(animation, forKey: "scale")
        } else {
            currentItemView = nil
        }
    }
    
}

extension RadarView: CAAnimationDelegate {
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        viewToRemove?.removeFromSuperview()
        viewToRemove = nil
    }
    
}

// MARK: public methods
extension RadarView {
    
    public func clear() {
        layer.removeAllAnimations()
        circleLayers.forEach { circleLayer in
            circleLayer.removeAllAnimations()
            circleLayer.removeFromSuperlayer()
        }
        circles.forEach { circle in
            circle.itemViews.forEach { itemView in
                itemView.view.layer.removeAllAnimations()
                itemView.view.layer.removeFromSuperlayer()
            }
            circle.clear()
        }
        circles.removeAll()
    }
    
    /// Start the ripple animation
    public func startAnimation() {
        layer.removeAllAnimations()
        circlesAnimationTimer?.invalidate()
        diskAnimationTimer?.invalidate()
        let timeInterval = 2.0
        diskAnimationTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(animateCentralDisk), userInfo: nil, repeats: true)
        //startIndicatorAnimation(timeInterval)
    }
    
    public func startIndicatorAnimation(_ delay: TimeInterval = 0) {
        indicator.alpha = 0
        indicator.origin = self.center
        indicator.indicatorColor = diskColor
        indicator.radius = (self.bounds.width / 2) - paddingBetweenCircles
        UIView.animate(withDuration: 0.25, delay: delay, animations: {
            self.indicator.alpha = 1
        })
        indicator.startAnimation()
    }
    
    /// Stop the ripple animation
    public func stopAnimation() {
        //stopIndicatorAnimation()
        layer.removeAllAnimations()
        circlesAnimationTimer?.invalidate()
        diskAnimationTimer?.invalidate()
    }
    
    public func stopIndicatorAnimation() {
        UIView.animate(withDuration: 0.25, animations: {
            self.indicator.alpha = 0
        }, completion: { _ in
            self.indicator.stopAnimation()
        })
        
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
        removeWithAnimation(view: itemView.view)
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
    
    public func rotate(degrees: Double, with duration: TimeInterval = 1.5, _ completion: (() -> ())? = nil) {
        circles.forEach { circle in
            circle.rotate(degrees, duration)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
            completion?()
        }
    }
    
}
