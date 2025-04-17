//
//  TouchData.swift
//  fw_note
//
//  Created by Fung Wing on 16/4/2025.
//

import UIKit

struct TouchData {
    var majorRadius: CGFloat
    var type: UITouch.TouchType
    var location: CGPoint
    var startLocation: CGPoint
    var translation: CGSize
    var predictedEndLocation: CGPoint
    var predictedEndTranslation: CGSize
    var time: Date
}
