//
//  CanvasObj.swift
//  fw_note
//
//  Created by Fung Wing on 26/3/2025.
//

import SwiftUI

class CanvasObj: ObservableObject, Identifiable, Codable, Equatable {
    let id: UUID
    var lineObj: LineObj?
    var imageObj: ImageObj?

    // Initializer
    init(id: UUID = UUID(), lineObj: LineObj?, imageObj: ImageObj?) {
        self.id = id
        self.lineObj = lineObj ?? nil
        self.imageObj = imageObj ?? nil
    }

    // Deep copy method
    func clone() -> CanvasObj {
        return CanvasObj(
            id: id,
            lineObj: lineObj?.clone() ?? nil,  // Assuming LineObj has a `clone` method
            imageObj: imageObj?.clone()  ?? nil  // Assuming ImageObj has a `clone` method
        )
    }

    static func == (lhs: CanvasObj, rhs: CanvasObj) -> Bool {
        return lhs.id == rhs.id && lhs.lineObj == rhs.lineObj
            && lhs.imageObj == rhs.imageObj
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
        imageObj = try container.decodeIfPresent(
            ImageObj.self, forKey: .imageObj)
    }
}
