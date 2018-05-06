
//  Drawer.swift
//  HGNearbyUsers_Example
//
//  Created by Hamza Ghazouani on 24/01/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

struct Drawer {

    static func diskView(radius: CGFloat, origin: CGPoint, color: UIColor) -> UIView {
        let frame = CGRect(x: 0, y: 0, width: radius*2, height: radius*2)
        let view = UIView(frame: frame)
        view.center = origin
        view.layer.cornerRadius = radius
        view.clipsToBounds = true
        view.backgroundColor = color
        return view
    }
    
    private static func layer(radius: CGFloat, origin: CGPoint) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.bounds = CGRect(x: 0, y: 0, width: radius*2, height: radius*2)
        layer.position = origin
        let center = CGPoint(x: radius, y: radius)
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        layer.path = path.cgPath
        return layer
    }
    
    static func diskLayer(radius: CGFloat, origin: CGPoint, color: CGColor) -> CAShapeLayer {
        let diskLayer = self.layer(radius: radius, origin: origin)
        diskLayer.fillColor = color
        return diskLayer
    }
    
    static func circleLayer(radius: CGFloat, origin: CGPoint, color: CGColor = UIColor.clear.cgColor) -> CAShapeLayer {
        let circleLayer = self.layer(radius: radius, origin: origin)
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = color
        circleLayer.lineWidth = 1.0
        return circleLayer
    }
    
}
