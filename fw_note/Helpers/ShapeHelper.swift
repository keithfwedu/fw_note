//
//  ShapeHelper.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import SwiftUI

class ShapeHelper {
    
    static func lineToShape(_ line: Line) -> [CGPoint] {
        let shape = ShapeHelper.predictLineShape(line)
       
        // Proceed with transformation based on the identified shape
        switch shape {
        case "straight":
            print("Modify to straight line")
            return lineToStraightLine(line)
        case "curve":
            print("Modify to curve")
            return lineToCurve(line)
        case "circle":
            print("Modify to circle")
            return lineToCircle(line)
        default:
            print("Unknown shape. No transformation applied.")
            return []
        }
    }
    
    static func predictLineShape(_ line: Line) -> String {
        if isStraightLine(line) {
            return "straight"
        }

        if isCircle(line) {
            return "circle"
        }

        return "curve"
    }

    static func lineToStraightLine(_ line: Line) -> [CGPoint] {
        print("Line \(line.id) converted to a refined straight line.")
        guard let firstPoint = line.points.first,
            let lastPoint = line.points.last
        else {
            return []
        }
        return [firstPoint, lastPoint]
    }

    static func lineToCurve(_ line: Line) -> [CGPoint] {
        print("Line \(line.id) converted to a refined Bézier curve.")
        guard let firstPoint = line.points.first,
            let lastPoint = line.points.last
        else {
            return []

        }
        let controlPoint =
            line.points.max(by: { pointA, pointB in
                let deviationA = PointHelper.perpendicularDistance(
                    from: pointA, toLineWithStart: firstPoint, end: lastPoint
                )
                let deviationB = PointHelper.perpendicularDistance(
                    from: pointB, toLineWithStart: firstPoint, end: lastPoint
                )
                return deviationA < deviationB
            }) ?? firstPoint

        let directionAdjustment: CGFloat = 0.4
        let adjustedControlPoint = CGPoint(
            x: controlPoint.x + (controlPoint.x - firstPoint.x)
                * directionAdjustment,
            y: controlPoint.y + (controlPoint.y - firstPoint.y)
                * directionAdjustment
        )

        return (0...100).map { t -> CGPoint in
            let t = CGFloat(t) / 100
            let oneMinusT = 1 - t

            let x =
                oneMinusT * oneMinusT * firstPoint.x + 2 * oneMinusT * t
                * adjustedControlPoint.x + t * t * lastPoint.x
            let y =
                oneMinusT * oneMinusT * firstPoint.y + 2 * oneMinusT * t
                * adjustedControlPoint.y + t * t * lastPoint.y

            return CGPoint(x: x, y: y)
        }

    }

    static func lineToCircle(_ line: Line) -> [CGPoint] {
        print("Line \(line.id) converted to a refined circlee.")
        guard let (circleCenter, radius) = fitCircleToPoints(to: line.points)
        else {
            return []
        }
        return (0...360).map { angle -> CGPoint in
            let radians = CGFloat(angle) * .pi / 180
            return CGPoint(
                x: circleCenter.x + radius * cos(radians),
                y: circleCenter.y + radius * sin(radians)
            )
        }
    }

    static func isStraightLine(_ line: Line) -> Bool {
        guard line.points.count >= 3 else { return true }

        let firstPoint = line.points.first!
        let lastPoint = line.points.last!

        let maxDeviation =
            line.points.map { point -> CGFloat in
                let deltaY = lastPoint.y - firstPoint.y
                let deltaX = lastPoint.x - firstPoint.x
                let numerator = abs(
                    deltaY * point.x - deltaX * point.y + lastPoint.x
                        * firstPoint.y - lastPoint.y * firstPoint.x)
                let denominator = hypot(deltaX, deltaY)
                return numerator / denominator
            }.max() ?? 0.0

        return maxDeviation < 15.0
    }

    static func isCircle(_ line: Line) -> Bool {
        let firstPoint = line.points.first!
        let lastPoint = line.points.last!
        // Calculate bounding box and roundness
        let minX = line.points.map { $0.x }.min() ?? 0
        let maxX = line.points.map { $0.x }.max() ?? 0
        let minY = line.points.map { $0.y }.min() ?? 0
        let maxY = line.points.map { $0.y }.max() ?? 0
        let majorAxis = max(maxX - minX, maxY - minY)
        let minorAxis = min(maxX - minX, maxY - minY)
        let roundnessRatio = minorAxis / majorAxis

        // Measure angular span
        let angularSpan = calculateAngularCoverage(of: line.points)

        // Measure distance between endpoints
        let endpointDistance = PointHelper.distance(firstPoint, lastPoint)
        let approximateDiameter = majorAxis

        // Classify as "circle-like" if:
        // - It's round (roundness ratio > 0.7)
        // - Angular span is at least 5/6 of a circle (300° or more)
        // - The endpoints are reasonably close (less than half the diameter)
        return roundnessRatio > 0.7 && angularSpan > CGFloat.pi * 5 / 3
            && endpointDistance < approximateDiameter / 2
    }

    static private func calculateAngularCoverage(of points: [CGPoint])
        -> CGFloat
    {
        guard let center = fitCircleToPoints(to: points)?.center else { return 0 }

        // Compute angles of each point relative to the center
        let angles = points.map { point in
            atan2(point.y - center.y, point.x - center.x)
        }.sorted()  // Sort angles to measure span

        // Wrap around the circle (account for the jump between -π and π)
        let angleDifferences = zip(angles, angles.dropFirst()).map {
            abs($1 - $0)
        }
        let totalSpan =
            angleDifferences.reduce(0, +)
            + (CGFloat.pi * 2 - abs(angles.last! - angles.first!))

        return totalSpan
    }

    static func fitCircleToPoints(to points: [CGPoint]) -> (
        center: CGPoint, radius: CGFloat
    )? {
        guard points.count >= 3 else { return nil }  // At least 3 points are needed

        // Step 1: Calculate an initial estimate for the center using averages
        let averageX = points.map { $0.x }.reduce(0, +) / CGFloat(points.count)
        let averageY = points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
        var center = CGPoint(x: averageX, y: averageY)

        // Step 2: Iteratively refine the center to minimize radius variance
        let maxIterations = 10
        for _ in 0..<maxIterations {
            // Calculate distances from the current center to all points
            let distances = points.map { PointHelper.distance($0, center) }
            let averageRadius =
                distances.reduce(0, +) / CGFloat(distances.count)

            // Adjust the center to reduce radius variance
            let adjustments = points.map { point -> CGPoint in
                let dx = point.x - center.x
                let dy = point.y - center.y
                let dist = hypot(dx, dy)
                let adjustmentFactor = (dist - averageRadius) / dist
                return CGPoint(
                    x: point.x - dx * adjustmentFactor,
                    y: point.y - dy * adjustmentFactor)
            }

            // Calculate the new center as the average of the adjustments
            let adjustedX =
                adjustments.map { $0.x }.reduce(0, +)
                / CGFloat(adjustments.count)
            let adjustedY =
                adjustments.map { $0.y }.reduce(0, +)
                / CGFloat(adjustments.count)
            center = CGPoint(x: adjustedX, y: adjustedY)
        }

        // Step 3: Final radius calculation
        let finalDistances = points.map { PointHelper.distance($0, center) }
        let radius = finalDistances.reduce(0, +) / CGFloat(finalDistances.count)

        return (center, radius)
    }
}
