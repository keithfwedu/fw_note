//
//  EraseHelper.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//
import SwiftUI

class EraseHelper {
    static func eraseLines(lines: [Line], dragValue: DragGesture.Value) -> [Line] {
        let adjustedLocation = dragValue.location  // Adjust location if necessary
        var updatedLines: [Line] = []

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
                    Line(
                        color: line.color,
                        points: segment,
                        mode: line.mode
                    )
                )
            }
        }

        return updatedLines
    }
    
  
}
