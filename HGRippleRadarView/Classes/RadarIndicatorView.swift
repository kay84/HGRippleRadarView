//
//  Circle.swift
//  HGRippleRadarView
//
//  Created by H. Eren ÇELİK on 03.05.2018.
//

import UIKit

class RadarIndicatorView: UIView {
    
    private var shapeLayer: CAShapeLayer!
    
    var origin: CGPoint? {
        didSet {
            redrawSublayers()
        }
    }
    
    var indicatorColor: UIColor = UIColor.black {
        didSet {
            redrawSublayers()
        }
    }
    
    var isClockwise: Bool = true {
        didSet {
            redrawSublayers()
        }
    }
    
    var radius: CGFloat = UIScreen.main.bounds.size.width / 2 - 16 {
        didSet {
            redrawSublayers()
        }
    }
    
    var traceCount = 250 {
        didSet {
            redrawSublayers()
        }
    }
    
    private var isAnimating = false
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        redrawSublayers()
    }
    
    private func redrawSublayers() {
        guard let origin = origin else { return }
        layer.sublayers?.forEach { sublayer in
            sublayer.removeAllAnimations()
            sublayer.removeFromSuperlayer()
        }
        let path = UIBezierPath()
        path.move(to: CGPoint(x: origin.x, y: origin.y))
        path.addArc(withCenter: origin, radius: radius, startAngle: angleToRadians(-1), endAngle: angleToRadians(0), clockwise: true)
        shapeLayer = createShapeLayer(path, alpha: 1)
        for i in 1..<traceCount {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: origin.x, y: origin.y))
            path.addArc(withCenter: origin,
                             radius: radius,
                             startAngle: isClockwise ? angleToRadians(CGFloat(-i - 1)) : angleToRadians(CGFloat(i)),
                             endAngle: isClockwise ? angleToRadians(CGFloat(-i)) : angleToRadians(CGFloat(i + 1)),
                             clockwise: true)
            let layer = createShapeLayer(path, alpha: CGFloat(traceCount - i)/500.0)
            shapeLayer.addSublayer(layer)
        }
        self.layer.addSublayer(shapeLayer)
    }
    
    private func createShapeLayer(_ path: UIBezierPath, alpha: CGFloat) -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = self.bounds
        shapeLayer.lineWidth = 1
        shapeLayer.fillColor = indicatorColor.cgColor
        shapeLayer.opacity = Float(alpha)
        shapeLayer.path = path.cgPath
        return shapeLayer
    }
    
    func startAnimation() {
        if isAnimating { return }
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.toValue = isClockwise ? 2 * Double.pi : -2 * Double.pi
        animation.duration = 4
        animation.isCumulative = true
        animation.repeatCount = HUGE
        self.layer.add(animation, forKey: "indicator-rotation")
        isAnimating = true
    }
    
    func stopAnimation() {
        if !isAnimating { return }
        self.layer.removeAnimation(forKey: "indicator-rotation")
        isAnimating = false
    }
    
}
