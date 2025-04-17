//
//  DrawPoint.swiftDrawPoint.swift
//  fw_note
//
//  Created by Fung Wing on 16/4/2025.
//


import CoreGraphics
import Foundation

struct DrawPoint: Codable, Equatable {
    var point: CGPoint // Original CGPoint
    var time: TimeInterval // Timestamp when the point was created
    var pressure: CGFloat // Pressure associated with the point

    // Initializer for creating DrawPoint with x, y, time, and pressure
    init(x: CGFloat, y: CGFloat, time: TimeInterval = Date().timeIntervalSince1970, pressure: CGFloat = 1.0) {
        self.point = CGPoint(x: x, y: y)
        self.time = time
        self.pressure = pressure
    }

    // Initializer for creating DrawPoint from a CGPoint, time, and pressure
    init(point: CGPoint, time: TimeInterval = Date().timeIntervalSince1970, pressure: CGFloat = 1.0) {
        self.point = point
        self.time = time
        self.pressure = pressure
    }

    // Accessors for x and y coordinates of the point
    var x: CGFloat {
        get { point.x }
        set { point.x = newValue }
    }

    var y: CGFloat {
        get { point.y }
        set { point.y = newValue }
    }

    // Custom CodingKeys to encode/decode CGPoint manually
    enum CodingKeys: String, CodingKey {
        case pointX, pointY, time, pressure
    }

    // Custom initializer for decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .pointX)
        let y = try container.decode(CGFloat.self, forKey: .pointY)
        self.point = CGPoint(x: x, y: y)
        self.time = try container.decode(TimeInterval.self, forKey: .time)
        self.pressure = try container.decode(CGFloat.self, forKey: .pressure)
    }

    // Custom method for encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(point.x, forKey: .pointX)
        try container.encode(point.y, forKey: .pointY)
        try container.encode(time, forKey: .time)
        try container.encode(pressure, forKey: .pressure)
    }
}
