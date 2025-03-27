//
//  CustomDragValue.swift
//  fw_note
//
//  Created by Fung Wing on 27/3/2025.
//

import Foundation

struct CustomDragValue {
    let time: Date
    let location: CGPoint
    let startLocation: CGPoint
    let translation: CGSize
    let predictedEndTranslation: CGSize
    let predictedEndLocation: CGPoint
}
