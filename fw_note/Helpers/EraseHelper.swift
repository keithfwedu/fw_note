//
//  EraseHelper.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//
import SwiftUI

class EraseHelper {
    static func eraseLineObjs(
        canvasStack: [CanvasObj],
        dragValue: TouchData,
        eraserRadius: CGFloat = 8
    ) -> [CanvasObj] {
        let adjustedLocation = DrawPoint(x: dragValue.location.x, y: dragValue.location.y)
        
        
        var updatedCanvasStack: [CanvasObj] = []

        for canvasObj in canvasStack {
            // Skip objects that don't contain a lineObj
            guard let lineObj = canvasObj.lineObj else {
                updatedCanvasStack.append(canvasObj)
                continue
            }

            var isErased = false

            // Interpolate points to ensure no gaps
            let interpolatedPoints = interpolatePoints(
                points: lineObj.points, maxDistance: eraserRadius / 10
            )

            for point in interpolatedPoints {
                let currentDistance = PointHelper.distance(point, adjustedLocation)

                if currentDistance <= eraserRadius {
                    isErased = true
                    break
                }
            }

            // Only keep CanvasObj if the lineObj is not erased
            if !isErased {
                updatedCanvasStack.append(canvasObj)
            }
        }

        return updatedCanvasStack
    }

    static func eraseLines(
        canvasStack: [CanvasObj],
        dragValue: TouchData,
        eraserRadius: CGFloat = 8
    ) -> [CanvasObj] {
        let adjustedLocation = DrawPoint(x: dragValue.location.x, y: dragValue.location.y)
        var updatedCanvasStack: [CanvasObj] = []

        for canvasObj in canvasStack {
            // Skip objects that don't contain a lineObj
            guard let lineObj = canvasObj.lineObj else {
                updatedCanvasStack.append(canvasObj)
                continue
            }

            // Check if the eraser touches the line (optimize logic)
            let isTouchingLine = lineObj.points.contains { point in
                PointHelper.distance(point, adjustedLocation) <= eraserRadius
            }

            // If no touch detected, skip interpolation and keep the line unchanged
            if !isTouchingLine {
                updatedCanvasStack.append(canvasObj)
                continue
            }

            // Interpolate points to ensure there are no large gaps
            let interpolatedPoints = interpolatePoints(
                points: lineObj.points, maxDistance: eraserRadius / 2
            )
            var newSegments: [[DrawPoint]] = []
            var currentSegment: [DrawPoint] = []

            // Split the points into segments based on eraser radius
            for point in interpolatedPoints {
                let currentDistance = PointHelper.distance(point, adjustedLocation)

                if currentDistance > eraserRadius {
                    // Point is outside the eraser radius, add it to the current segment
                    currentSegment.append(point)
                } else {
                    // Point is within the eraser radius, split the line
                    if !currentSegment.isEmpty {
                        newSegments.append(currentSegment) // Save the current segment
                        currentSegment = [] // Start a new segment
                    }
                }
            }

            // Append the final segment if it exists
            if !currentSegment.isEmpty {
                newSegments.append(currentSegment)
            }

            // Reassemble segments into new CanvasObj objects
            for segment in newSegments where !segment.isEmpty {
                let newLineObj = LineObj(
                    color: lineObj.color,
                    points: segment,
                    lineWidth: lineObj.lineWidth,
                    mode: lineObj.mode
                )
                updatedCanvasStack.append(CanvasObj(lineObj: newLineObj, imageObj: nil))
            }
        }

        return updatedCanvasStack
    }


    static func interpolatePoints(points: [DrawPoint], maxDistance: CGFloat)
            -> [DrawPoint]
        {
            guard points.count > 1 else { return points }  // Return as-is if there are no points to interpolate
            var interpolatedPoints: [DrawPoint] = []

            for i in 0..<points.count - 1 {
                let start = points[i]
                let end = points[i + 1]
                interpolatedPoints.append(start)

                let distance = PointHelper.distance(start, end)
                if distance > maxDistance {
                    let numIntermediatePoints = Int(ceil(distance / maxDistance))
                    for j in 1..<numIntermediatePoints {
                        let t = CGFloat(j) / CGFloat(numIntermediatePoints)
                        let intermediatePoint = DrawPoint(
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

}
