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
    var angle: CGFloat = 0

    // Computed property to calculate the rectangle
    var rect: CGRect {
        
        let transformedSize = calculateBoundingSize(
            width: size.width,
            height: size.height,
            angle: angle
        )
        print("\(size.width),\(size.height) - \(transformedSize.width),\(transformedSize.height)")
        return CGRect(
            origin: CGPoint(
                x: position.x - transformedSize.width / 2,
                y: position.y - transformedSize.height / 2
            ),
            size: transformedSize
        )
    }
    
    
    func calculateBoundingSize(width: CGFloat, height: CGFloat, angle: CGFloat) -> CGSize {
        // Convert angle from degrees to radians
        let radians = angle * .pi / 180

        // Calculate the bounding width and height
        let boundingWidth = abs(width * cos(radians)) + abs(height * sin(radians))
        let boundingHeight = abs(width * sin(radians)) + abs(height * cos(radians))

        return CGSize(width: boundingWidth, height: boundingHeight)
    }


}
