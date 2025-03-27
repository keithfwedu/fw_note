//
//  PathHelper.swift
//  fw_note
//
//  Created by Fung Wing on 27/3/2025.
//
import SwiftUI

class PathHelper {
    
    static func createStableCurvedPath(
        points: [CGPoint], maxOffsetForAverage: Int, curveWeight: CGFloat = 0.2
    ) -> Path {
        var path = Path()
        let nPoints = points.count

        // Special case: Handle when there are only two points
        if nPoints == 2, let firstPoint = points.first, let secondPoint = points.last {
            path.move(to: firstPoint)
            path.addLine(to: secondPoint)
            return path // Return early since we don't need smoothing
        }

        let maxOffset = max(1, min(maxOffsetForAverage, nPoints / maxOffsetForAverage))
        var xSum = CGFloat.zero
        var ySum = CGFloat.zero
        var previousRangeBegin = 0
        var previousRangeEnd = 0

        for i in 0..<nPoints {
            let rangeBegin = max(0, i - maxOffset)
            let rangeEnd = min(nPoints - 1, i + maxOffset)

            if i == 0, let firstPoint = points.first {
                path.move(to: firstPoint)
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

                // Calculate the midpoint for stability
                let sampleSize = CGFloat(rangeEnd - rangeBegin + 1)
                let smoothPoint = CGPoint(
                    x: xSum / sampleSize, y: ySum / sampleSize
                )

                // Blend smoothPoint with previous point using a smaller weight
                let controlPoint = CGPoint(
                    x: (1 - curveWeight) * points[i - 1].x + curveWeight * smoothPoint.x,
                    y: (1 - curveWeight) * points[i - 1].y + curveWeight * smoothPoint.y
                )

                // Use midpoint between previous and current for subtle curves
                let midPoint = CGPoint(
                    x: (points[i - 1].x + smoothPoint.x) / 2,
                    y: (points[i - 1].y + smoothPoint.y) / 2
                )

                // Add a subtle curve to the next point
                path.addQuadCurve(to: midPoint, control: controlPoint)
            }
            previousRangeBegin = rangeBegin
            previousRangeEnd = rangeEnd
        }

        if nPoints > 2, let lastPoint = points.last {
            path.addLine(to: lastPoint)
        }

        return path
    }

}
