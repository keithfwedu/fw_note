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
    var size: CGSize = .zero
    var isGIF: Bool = false

    // Computed property for absolutePath
    var absolutePath: String {
        guard let projectId = currentProjectId else {
            //print("Error: currentProjectId is nil")
            return "" // Return an empty string or handle this scenario appropriately
        }
        return FileHelper.getUserImageFilePath(imageName: path, projectId: projectId) ?? ""
    }

    // Custom initializer
    init(path: String) {
        self.path = path
        self.size = Self.computeSize(for: path)
        self.isGIF = Self.checkIsGIF(for: path)
    }

    // Static method to compute image size
    private static func computeSize(for path: String) -> CGSize {
        guard let image = UIImage(contentsOfFile: FileHelper.getUserImageFilePath(imageName: path, projectId: currentProjectId!) ?? "") else {
            //print("Failed to load image from path: \(path)")
            return .zero
        }
        return image.size
    }

    // Static method to check if the image is a GIF
    private static func checkIsGIF(for path: String) -> Bool {
        guard let projectId = currentProjectId else {
            //print("Error: currentProjectId is nil")
            return false
        }
        let absolutePath = FileHelper.getUserImageFilePath(imageName: path, projectId: projectId) ?? ""
        return ImageHelper.isGIF(filePath: absolutePath)
    }

    // Custom decoding logic
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode 'path'
        self.path = try container.decode(String.self, forKey: .path)

        // Regenerate dependent properties
        self.size = Self.computeSize(for: path)
        self.isGIF = Self.checkIsGIF(for: path)

        // Decode 'id'
        self.id = try container.decode(UUID.self, forKey: .id)
    }

    // Custom encoding logic
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(path, forKey: .path)
    }

    // Define Codable keys
    private enum CodingKeys: String, CodingKey {
        case id
        case path
    }
}
