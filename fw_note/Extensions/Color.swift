//
//  Color.swift
//  fw_note
//
//  Created by Fung Wing on 20/3/2025.
//

import SwiftUI

extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, opacity
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        try container.encode(red, forKey: .red)
        try container.encode(green, forKey: .green)
        try container.encode(blue, forKey: .blue)
        try container.encode(alpha, forKey: .opacity)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(CGFloat.self, forKey: .red)
        let green = try container.decode(CGFloat.self, forKey: .green)
        let blue = try container.decode(CGFloat.self, forKey: .blue)
        let opacity = try container.decode(CGFloat.self, forKey: .opacity)
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    func toHex() -> String? {
        // Convert Color to UIColor
        guard let uiColor = UIColor(self).cgColor.components, uiColor.count >= 3
        else {
            return nil
        }

        let red = Int(uiColor[0] * 255)
        let green = Int(uiColor[1] * 255)
        let blue = Int(uiColor[2] * 255)

        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized =
            hexSanitized.hasPrefix("#")
            ? String(hexSanitized.dropFirst()) : hexSanitized

        let length = hexSanitized.count
        guard length == 6 || length == 8 else { return nil }

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        let alpha = length == 8 ? Double((rgb >> 24) & 0xFF) / 255.0 : 1.0

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
