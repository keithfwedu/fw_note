//
//  NotePage.swift
//  fw_note
//
//  Created by Fung Wing on 19/3/2025.
//

import SwiftUI

class NotePage: Identifiable, Codable, ObservableObject {
    var id = UUID()
    @Published var pageIndex: Int
    @Published var lineObjs: [LineObj] = []
    @Published var imageObjs: [ImageObj] = []
    @Published var gifObjs: [GifObj] = []
    @Published var zoomScale: CGFloat = 1.0

    init(pageIndex: Int) {
        print("pageIndex: \(pageIndex)")
        self.pageIndex = pageIndex
    }

    // Codable conformance
    private enum CodingKeys: String, CodingKey {
        case id, pageIndex, lineObjs, imageObjs, gifObjs
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        pageIndex = try container.decode(Int.self, forKey: .pageIndex)
        lineObjs = try container.decode([LineObj].self, forKey: .lineObjs)
        imageObjs = try container.decode([ImageObj].self, forKey: .imageObjs)
        gifObjs = try container.decode([GifObj].self, forKey: .gifObjs)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(pageIndex, forKey: .pageIndex)
        try container.encode(lineObjs, forKey: .lineObjs)
        try container.encode(imageObjs, forKey: .imageObjs)
        try container.encode(gifObjs, forKey: .gifObjs)
    }
}
