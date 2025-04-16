//
//  ImageView.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import UIKit

struct ImageObj: Identifiable, Codable, Equatable {
    let id: UUID
    var path: String?
    var position: CGPoint
    var size: CGSize
    var angle: CGFloat

    // CGImage is excluded from Codable

    private(set) var cgImage: CGImage?
    private(set) var animatedImage: UIImage?  // For animated GIFs

    func clone() -> ImageObj {
        return ImageObj(
            id: id,
            path: path,
            position: position,
            size: size,
            angle: angle
        )
    }


    // Initializer
    init(
        id: UUID = UUID(),
        path: String? = nil,
        position: CGPoint,
        size: CGSize,
        angle: CGFloat = 0
    ) {
        self.id = id
        self.path = path
        self.position = position
        self.size = size
        self.angle = angle
        self.cgImage = nil
    }

    var isAnimatedGIF: Bool {
        return path?.lowercased().hasSuffix(".gif") ?? false
    }

    // Computed property to calculate the rectangle
    var rect: CGRect {
        let transformedSize = calculateBoundingSize(
            width: size.width,
            height: size.height,
            angle: angle
        )
        return CGRect(
            origin: CGPoint(
                x: position.x - transformedSize.width / 2,
                y: position.y - transformedSize.height / 2
            ),
            size: transformedSize
        )
    }

    // Function to calculate bounding size after rotation
    func calculateBoundingSize(width: CGFloat, height: CGFloat, angle: CGFloat)
        -> CGSize
    {
        let radians = angle * .pi / 180
        let boundingWidth =
            abs(width * cos(radians)) + abs(height * sin(radians))
        let boundingHeight =
            abs(width * sin(radians)) + abs(height * cos(radians))
        return CGSize(width: boundingWidth, height: boundingHeight)
    }

    // Equatable conformance
    static func == (lhs: ImageObj, rhs: ImageObj) -> Bool {
        return lhs.id == rhs.id && lhs.path == rhs.path
            && lhs.position == rhs.position && lhs.size == rhs.size
            && lhs.angle == rhs.angle
    }
    
    func getAbsolutePath() -> String? {
        guard let path = self.path else {
            print("Error: Path is nil")
            return nil
        }
        
        guard let projectId = currentProjectId else {
            print("Error: currentProjectId is nil")
            return nil
        }
        
        guard
            let absolutePath = FileHelper.getProjectImageFilePath(
                imageName: path,
                projectId: projectId
            ) else {
            print("Error: absolutePath is nil")
            return nil
        }
                
            return absolutePath
    }

    // Load the CGImage from the path
    mutating func loadImageFromPath() {
        
        if(self.cgImage == nil) {
            guard let path = path else {
                print("Error: Path is nil")
                return
            }
            
            guard let projectId = currentProjectId else {
                print("Error: currentProjectId is nil")
                return
            }
            
            guard
                let absolutePath = FileHelper.getProjectImageFilePath(
                    imageName: path,
                    projectId: projectId
                )
            else {
                print("Error: absolutePath is nil")
                return
            }
            
           /* if isAnimatedGIF,
               (try? Data(contentsOf: URL(fileURLWithPath: absolutePath))) != nil
            {
                // Load animated GIF as UIImage
                 //animatedImage = UIImage.animatedImage(withAnimatedGIFData: data)
                 //cgImage = animatedImage?.cgImage
            } else*/ if let uiImage = UIImage(contentsOfFile: absolutePath) {
                // Load static image as CGImage
                animatedImage = nil
                cgImage = uiImage.cgImage
            } else {
                print("Error: Unable to load image at path \(absolutePath)")
                cgImage = UIImage(systemName: "photo")!.cgImage!
            }
        }

    }

    // MARK: - Codable Conformance
    enum CodingKeys: String, CodingKey {
        case id
        case path
        case position
        case size
        case angle
        // Exclude cgImage from Codable
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(path, forKey: .path)
        try container.encode(position, forKey: .position)
        try container.encode(size, forKey: .size)
        try container.encode(angle, forKey: .angle)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        path = try container.decode(String?.self, forKey: .path)
        position = try container.decode(CGPoint.self, forKey: .position)
        size = try container.decode(CGSize.self, forKey: .size)
        angle = try container.decode(CGFloat.self, forKey: .angle)

        // Load the CGImage during decoding
        self.cgImage = nil
     
    }
}
