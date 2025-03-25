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
    var points: [CGPoint]
    var lineWidth: CGFloat
    var opacity: Double = 1.0
    var mode: CanvasMode

    // Equatable conformance
    static func == (lhs: LineObj, rhs: LineObj) -> Bool {
        return lhs.id == rhs.id &&
               lhs.color == rhs.color &&
               lhs.points == rhs.points &&
               lhs.lineWidth == rhs.lineWidth &&
               lhs.mode == rhs.mode
    }

    // Initializer for convenience
    init(id: UUID = UUID(), color: Color, points: [CGPoint], lineWidth: CGFloat, mode: CanvasMode) {
        self.id = id
        self.color = color
        self.points = points
        self.lineWidth = lineWidth
        self.mode = mode
    }
}
