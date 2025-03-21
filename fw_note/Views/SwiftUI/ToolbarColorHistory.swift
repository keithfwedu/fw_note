//
//  ToolbarColorHistory.swift
//  pdf_note
//
//  Created by Alex Ng on 8/3/2025.
//

import SwiftUI

struct ToolbarColorHistory {
    private static let recentColorsKey = "recentColors"

    static func saveRecentColors(colors: [Color]) {
        let colorData = colors.map { UIColor($0).toHexString() }
        UserDefaults.standard.set(colorData, forKey: recentColorsKey)
    }

    static func loadRecentColors() -> [Color] {
        guard let colorData = UserDefaults.standard.array(forKey: recentColorsKey) as? [String] else {
            return []
        }
        return colorData.compactMap { Color($0) }
    }
}


import UIKit

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    func toHexString() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255)
        
        return String(format: "#%06x", rgb).uppercased()
    }
}
