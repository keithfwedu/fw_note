//
//  OringalImageObj.swift
//  fw_note
//
//  Created by Fung Wing on 2/4/2025.
//

import UIKit

struct OriginalImageObj: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var path: String
    var absolutePath: String // Stored property
    var size: CGSize = .zero
    var isGIF: Bool = false

    // Custom initializer
    init(path: String) {
        self.path = path
        self.absolutePath = Self.setAbsolutePath(path: path)
        self.setSize()
        self.setIsGIF()
    }

    // Static method to compute absolute path
    static func setAbsolutePath(path: String) -> String {
        let imageDirectory = AppState.getImageDirectory()

        guard let fileURL = imageDirectory?.appendingPathComponent(path) else {
            print("Error get fileURL")
            return path
        }

        print("fileURL.path \(fileURL)")
        return fileURL.path
    }

    mutating func setSize() {
        print("path2: \(absolutePath)")
        guard let image = UIImage(contentsOfFile: absolutePath) else {
            print("Failed to load image from path: \(absolutePath)")
            return
        }

        self.size = image.size
    }

    mutating func setIsGIF() {
        self.isGIF = ImageHelper.isGIF(filePath: absolutePath)
    }

    // Custom decoding logic
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode 'path' first
        self.path = try container.decode(String.self, forKey: .path)

        // Generate 'absolutePath' based on the decoded 'path'
        self.absolutePath = Self.setAbsolutePath(path: path)

        // Decode other properties
        self.id = try container.decode(UUID.self, forKey: .id)
        self.size = .zero // Default; will be calculated later
        self.isGIF = false // Default; will be calculated later

        // Regenerate dependent properties
        self.setSize()
        self.setIsGIF()
    }

    // Custom encoding logic (if needed)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(path, forKey: .path)
        // Other properties can be encoded as needed
    }

    // Define Codable keys
    private enum CodingKeys: String, CodingKey {
        case id
        case path
    }
}
