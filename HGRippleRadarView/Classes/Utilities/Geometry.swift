//
//  Geometry.swift
//  HGNearbyUsers_Example
//
//  Created by Hamza Ghazouani on 25/01/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

struct Geometry {

    /**
     Given a specific angle, returns the coordinates of the point in the circle
     
     - parameter angle:  the angle value
     - parameter circle: the circle
     
     - returns: the coordinates of the end point
     */
    public static func point(in angle: CGFloat, of circle: Circle) -> CGPoint {
        /*
         to get coordinate from angle of circle
         https://www.mathsisfun.com/polar-cartesian-coordinates.html
         */
        
        let x = circle.radius * cos(angle) + circle.origin.x // cos(α) = x / radius
        let y = circle.radius * sin(angle) + circle.origin.y // sin(α) = y / radius
        let point = CGPoint(x: x, y: y)
        
        return point
    }
    
}
