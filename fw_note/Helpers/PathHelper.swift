//
//  PathHelper.swift
//  fw_note
//
//  Created by Fung Wing on 27/3/2025.
//
import SwiftUI

class PathHelper {
    
    static func createStableCurvedPath(points: [DrawPoint], maxOffsetForAverage: CGFloat, curveWeight: CGFloat = 0.2) -> Path {
        var path = Path() // Initialize the Path object
        let nPoints = points.count
        guard nPoints > 1 else { return path } // Return an empty path if fewer than 2 points

        // Convert maxOffsetForAverage to an effective integer range
        let lowerOffset = Int(floor(maxOffsetForAverage))
        let upperOffset = Int(ceil(maxOffsetForAverage))
        let fractionalWeight = maxOffsetForAverage - CGFloat(lowerOffset)

        var xSum = CGFloat.zero
        var ySum = CGFloat.zero
        var previousRangeBegin = 0
        var previousRangeEnd = 0

        for i in 0..<nPoints {
            // Dynamically compute an interpolated offset
            let interpolatedOffset = Int(
                CGFloat(lowerOffset) * (1 - fractionalWeight) + CGFloat(upperOffset) * fractionalWeight
            )
            let rangeBegin = max(0, i - interpolatedOffset)
            let rangeEnd = min(nPoints - 1, i + interpolatedOffset)

            if i == 0, let firstPoint = points.first {
                path.move(to: CGPoint(x: firstPoint.x, y: firstPoint.y))
                for point in points[rangeBegin...rangeEnd] {
                    xSum += point.x
                    ySum += point.y
                }
            } else {
                if rangeBegin > previousRangeBegin {
                    let previousPoint = points[previousRangeBegin]
                    xSum -= previousPoint.x
                    ySum -= previousPoint.y
                }
                if rangeEnd > previousRangeEnd {
                    let endPoint = points[rangeEnd]
                    xSum += endPoint.x
                    ySum += endPoint.y
                }

                let sampleSize = CGFloat(rangeEnd - rangeBegin + 1)
                let smoothPoint = CGPoint(x: xSum / sampleSize, y: ySum / sampleSize)
                path.addLine(to: smoothPoint)
            }

            previousRangeBegin = rangeBegin
            previousRangeEnd = rangeEnd
        }

        if nPoints > 2, let lastPoint = points.last {
            path.addLine(to: CGPoint(x: lastPoint.x, y: lastPoint.y))
        }

        return path
    }


}
