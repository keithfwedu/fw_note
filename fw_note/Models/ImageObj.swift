//
//  ImageView.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import SwiftUI

struct ImageObj: Identifiable, Codable, Equatable {
    let id: UUID
    var path: String?
    var position: CGPoint
    var size: CGSize
    var angle: CGFloat

    // Computed property to calculate the rectangle
    var rect: CGRect {
        let transformedSize = calculateBoundingSize(
            width: size.width,
            height: size.height,
            angle: angle
        )
        return CGRect(
            origin: CGPoint(
                x: position.x - transformedSize.width / 2,
                y: position.y - transformedSize.height / 2
            ),
            size: transformedSize
        )
    }

    // Function to calculate bounding size after rotation
    func calculateBoundingSize(width: CGFloat, height: CGFloat, angle: CGFloat) -> CGSize {
        let radians = angle * .pi / 180
        let boundingWidth = abs(width * cos(radians)) + abs(height * sin(radians))
        let boundingHeight = abs(width * sin(radians)) + abs(height * cos(radians))
        return CGSize(width: boundingWidth, height: boundingHeight)
    }

    // Equatable conformance
    static func == (lhs: ImageObj, rhs: ImageObj) -> Bool {
        return lhs.id == rhs.id &&
               lhs.path == rhs.path &&
               lhs.position == rhs.position &&
               lhs.size == rhs.size &&
               lhs.angle == rhs.angle
    }

    // Initializer for convenience
    init(id: UUID = UUID(), path: String? = nil, position: CGPoint, size: CGSize, angle: CGFloat = 0) {
        self.id = id
        self.path = path
        self.position = position
        self.size = size
        self.angle = angle
    }
}
