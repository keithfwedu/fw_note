//
//  EraseHelper.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//
import SwiftUI

class EraseHelper {
    static func eraseLineObjs(
        lines: [LineObj], dragValue: DragGesture.Value,
        eraserRadius: CGFloat = 8
    ) -> [LineObj] {
        let adjustedLocation = dragValue.location
        var updatedLines: [LineObj] = []

        for line in lines {
            var isErased = false  // Flag to determine if the line should be erased

            // Iterate through consecutive pairs of points in the line (segments)

            let interpolatedPoints = interpolatePoints(
                points: line.points, maxDistance: eraserRadius/10)

            for point in interpolatedPoints {
                let currentDistance = PointHelper.distance(
                    point, adjustedLocation)

                if currentDistance <= eraserRadius {
                    isErased = true
                    break
                }
            }

            // Add the line to the updatedLines array only if it should not be erased
            if !isErased {
                updatedLines.append(line)
            }
        }

        return updatedLines
    }

    static func eraseLines(
        lines: [LineObj], dragValue: DragGesture.Value,
        eraserRadius: CGFloat = 8
    ) -> [LineObj] {
        let adjustedLocation = dragValue.location
        var updatedLines: [LineObj] = []

        for line in lines {
            // Step 1: Interpolate points to ensure there are no large gaps
            let interpolatedPoints = interpolatePoints(
                points: line.points, maxDistance: eraserRadius / 2)
            var newSegments: [[CGPoint]] = [[]]

            for point in interpolatedPoints {
                let currentDistance = PointHelper.distance(
                    point, adjustedLocation)

                if currentDistance > eraserRadius {
                    // Point is outside the eraser radius, add it to the current segment
                    newSegments[newSegments.count - 1].append(point)
                } else {
                    // Point is within the eraser radius, split the line
                    if !newSegments[newSegments.count - 1].isEmpty {
                        newSegments.append([])  // Start a new segment
                    }
                }
            }

            // Step 2: Reassemble segments into new LineObj objects
            for segment in newSegments where !segment.isEmpty {
                updatedLines.append(
                    LineObj(
                        color: line.color,
                        points: segment,
                        lineWidth: line.lineWidth,
                        mode: line.mode
                    )
                )
            }
        }

        return updatedLines
    }

    static func interpolatePoints(points: [CGPoint], maxDistance: CGFloat)
        -> [CGPoint]
    {
        guard points.count > 1 else { return points }  // Return as-is if there are no points to interpolate
        var interpolatedPoints: [CGPoint] = []

        for i in 0..<points.count - 1 {
            let start = points[i]
            let end = points[i + 1]
            interpolatedPoints.append(start)

            let distance = PointHelper.distance(start, end)
            if distance > maxDistance {
                let numIntermediatePoints = Int(ceil(distance / maxDistance))
                for j in 1..<numIntermediatePoints {
                    let t = CGFloat(j) / CGFloat(numIntermediatePoints)
                    let intermediatePoint = CGPoint(
                        x: start.x + t * (end.x - start.x),
                        y: start.y + t * (end.y - start.y)
                    )
                    interpolatedPoints.append(intermediatePoint)
                }
            }
        }

        interpolatedPoints.append(points.last!)  // Add the final point
        return interpolatedPoints
    }

    /*static func eraseLines(lines: [LineObj], dragValue: DragGesture.Value) -> [LineObj] {
        let adjustedLocation = dragValue.location  // Adjust location if necessary
        var updatedLines: [LineObj] = []

        for i in (0..<lines.count).reversed() {
            let line = lines[i]
            var newSegments: [[CGPoint]] = [[]]
            var lastErased = false

            for point in line.points {
                let currentDistance = PointHelper.distance(
                    point, adjustedLocation)
                if currentDistance > 15 {  // Erase radius
                    if lastErased {
                        newSegments.append([])
                    }
                    newSegments[newSegments.count - 1].append(point)
                    lastErased = false
                } else {
                    lastErased = true
                }
            }

            for segment in newSegments where !segment.isEmpty {
                updatedLines.append(
                    LineObj(
                        color: line.color,
                        points: segment,
                        lineWidth: line.lineWidth,
                        mode: line.mode
                    )
                )
            }
        }

        return updatedLines
    }*/

}
