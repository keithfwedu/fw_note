//
//  Line.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import SwiftUI

struct LineObj: Identifiable, Codable {
    var id = UUID()
    var color: Color
    var points: [CGPoint]
    var lineWidth: CGFloat
    var mode: CanvasMode
}
