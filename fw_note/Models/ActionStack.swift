//
//  ActionStack.swift
//  fw_note
//
//  Created by Fung Wing on 19/3/2025.
//

import Foundation

struct ActionStack: Identifiable, Codable {
    var id = UUID()
    var pageIndex: Int
    var canvasStack: [CanvasObj]?
}
