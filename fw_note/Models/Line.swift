//
//  Line.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import SwiftUI

struct Line: Identifiable {
    let id = UUID()
    var color: Color
    var points: [CGPoint]
    var mode: CanvasMode
}
