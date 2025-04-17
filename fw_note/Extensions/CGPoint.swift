//
//  GCPoint.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import SwiftUI

extension CGPoint {
    enum CodingKeys: String, CodingKey {
        case x, y
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }
    
    func toDrawPoint() -> DrawPoint {
        return DrawPoint(x: self.x, y: self.y)
    }
}
