//
//  CanvasObj.swift
//  fw_note
//
//  Created by Fung Wing on 26/3/2025.
//

import SwiftUI

class CanvasObj: ObservableObject, Identifiable, Codable, Equatable {
    var id = UUID()
    var lineObj: LineObj? = nil
    var imageObj: ImageObj? = nil

    // Default initializer
    init() {
        self.lineObj = nil
        self.imageObj = nil
    }
    
    static func == (lhs: CanvasObj, rhs: CanvasObj) -> Bool {
        return lhs.id == rhs.id &&
               lhs.lineObj == rhs.lineObj &&
               lhs.imageObj == rhs.imageObj
    }

    // Initializer with parameters
    init(lineObj: LineObj?, imageObj: ImageObj?) {
        self.lineObj = lineObj
        self.imageObj = imageObj
    }

    // Codable conformance
    enum CodingKeys: String, CodingKey {
        case id
        case lineObj
        case imageObj
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(lineObj, forKey: .lineObj)
        try container.encode(imageObj, forKey: .imageObj)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        lineObj = try container.decodeIfPresent(LineObj.self, forKey: .lineObj)
        imageObj = try container.decodeIfPresent(ImageObj.self, forKey: .imageObj)
    }

    // Helper method to validate object contents
    func isEmpty() -> Bool {
        [lineObj, imageObj].allSatisfy { $0 == nil }
    }
}
