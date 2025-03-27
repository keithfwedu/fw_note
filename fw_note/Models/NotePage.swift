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
    @Published var canvasStack: [CanvasObj] = []
    

    init(pageIndex: Int) {
        print("pageIndex: \(pageIndex)")
        self.pageIndex = pageIndex
    }

    // Codable conformance
    private enum CodingKeys: String, CodingKey {
        case id, pageIndex, canvasStack
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        pageIndex = try container.decode(Int.self, forKey: .pageIndex)
        canvasStack = try container.decode(
            [CanvasObj].self, forKey: .canvasStack)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(pageIndex, forKey: .pageIndex)
        try container.encode(canvasStack, forKey: .canvasStack)
    }
}
