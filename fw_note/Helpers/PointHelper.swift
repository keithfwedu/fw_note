//
//  PointHelper.swift
//  fw_note
//
//  Created by Fung Wing on 20/3/2025.
//

import SwiftUI

class PointHelper {
    // Utility function to interpolate points for smoother paths
    static func interpolatePoints(
        from start: CGPoint, to end: CGPoint, step: CGFloat = 10.0
    ) -> [CGPoint] {
        let distance = sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2))
        let steps = max(1, Int(distance / step))
        return (0...steps).map { i in
            // Apply an easing function for smoother interpolation
            let t = CGFloat(i) / CGFloat(steps)
            let easedT = cubicEaseOut(t) // Replace this with your desired easing function
            return CGPoint(
                x: start.x + easedT * (end.x - start.x),
                y: start.y + easedT * (end.y - start.y)
            )
        }
    }

    // Cubic easing out function
    static func cubicEaseOut(_ t: CGFloat) -> CGFloat {
        return 1 - pow(1 - t, 3) // Eases out, starts fast and slows down towards the end
    }


  
    static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    }
    
    static func perpendicularDistance(
        from point: CGPoint, toLineWithStart lineStart: CGPoint,
        end lineEnd: CGPoint
    ) -> CGFloat {
        let numerator = abs(
            (lineEnd.y - lineStart.y) * point.x - (lineEnd.x - lineStart.x)
                * point.y + lineEnd.x * lineStart.y - lineEnd.y * lineStart.x)
        let denominator = hypot(
            lineEnd.x - lineStart.x, lineEnd.y - lineStart.y)
        return numerator / denominator
    }
}
