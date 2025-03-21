//
//  ImageView.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import SwiftUI

struct ImageObj: Identifiable, Codable {
    let id: UUID
    var path: String?
    var position: CGPoint
    var size: CGSize
    var rotation: CGFloat = 0

    // Computed property to calculate the rectangle
    var rect: CGRect {
        CGRect(
            origin: CGPoint(
                x: position.x - size.width / 2,
                y: position.y - size.height / 2
            ),
            size: size
        )
    }

}
