//
//  Line.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import SwiftUI

struct LineObj: Identifiable, Codable, Equatable {
    var id = UUID()
    var color: Color
    var points: [DrawPoint]
    var lineWidth: CGFloat
    var opacity: Double = 1.0
    
    var mode: CanvasMode
    
    
    func clone() -> LineObj {
        return LineObj(id: id, color: color, points: points, lineWidth: lineWidth, mode: mode)
    }
    
    func updatePoints(_ newPoints: [DrawPoint]) -> LineObj {
        LineObj(id: id, color: color, points: newPoints, lineWidth: lineWidth, mode: mode)
    }

    // Equatable conformance
    static func == (lhs: LineObj, rhs: LineObj) -> Bool {
        return lhs.id == rhs.id &&
               lhs.color == rhs.color &&
               lhs.points == rhs.points &&
               lhs.lineWidth == rhs.lineWidth &&
               lhs.mode == rhs.mode
    }

    // Initializer for convenience
    init(id: UUID = UUID(), color: Color, points: [DrawPoint], lineWidth: CGFloat, mode: CanvasMode) {
        self.id = id
        self.color = color
        self.points = points
        self.lineWidth = lineWidth
        self.mode = mode
    }
}
