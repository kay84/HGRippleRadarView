//
//  Geometry.swift
//  HGNearbyUsers_Example
//
//  Created by Hamza Ghazouani on 25/01/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

internal func angleToRadians(_ angle: CGFloat) -> CGFloat {
    return angle.degreesToRadians
}

extension CGRect {
    
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
    
}

extension FloatingPoint {
    
    var degreesToRadians: Self { return self * .pi / 180 }
    
    var radiansToDegrees: Self { return self * 180 / .pi }
    
}

struct Geometry {

    public static func point(in angle: CGFloat, of circle: Circle) -> CGPoint {
        let x = circle.radius * cos(angle) + circle.origin.x // cos(α) = x / radius
        let y = circle.radius * sin(angle) + circle.origin.y // sin(α) = y / radius
        let point = CGPoint(x: x, y: y)
        return point
    }
    
    public static func angle(of point: CGPoint, in circle: Circle) -> CGFloat {
        let absoluteZero = CGPoint.init(x: 0, y: 0)
        var angle = CGFloat(atan2(point.y, absoluteZero.y) - atan2(point.x, absoluteZero.x))
        angle = angle * 180 / .pi
        if (angle < 0) {
            angle += 360
        }
        return angle
    }
    
    public static func arc(from point: CGPoint, by angle: CGFloat, in circle: Circle) -> UIBezierPath {
        print("point ::: \(point)")
        let startAngle = Geometry.angle(of: point, in: circle)
        let endAngle = startAngle + angle
        let clockwise = angle >= 0 && endAngle <= 180
        print("startAngle - endAngle ::: \(startAngle) - \(endAngle)")
        let path = UIBezierPath.init(arcCenter: circle.origin, radius: circle.radius, startAngle: startAngle.degreesToRadians, endAngle: endAngle.degreesToRadians, clockwise: clockwise)
        return path
    }
    
    /*
    public static func arc(from point1: CGPoint, to point2: CGPoint, in circle: Circle) -> UIBezierPath {
        let startAngle = Geometry.angle(of: point1, in: circle)
        let endAngle = Geometry.angle(of: point2, in: circle)
        let path = UIBezierPath.init(arcCenter: circle.origin, radius: circle.radius, startAngle: startAngle.degreesToRadians, endAngle: endAngle.degreesToRadians, clockwise: true)
        return path
    }
    */
    
}
