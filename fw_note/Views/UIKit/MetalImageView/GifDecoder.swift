//
//  GifDecoder.swift
//  fw_note
//
//  Created by Fung Wing on 24/3/2025.
//


import UIKit
import ImageIO

class GIFDecoder {
    static func decodeGIF(from path: String) -> [(UIImage, Double)]? {
        let gifURL = URL(fileURLWithPath: path)
        guard let gifData = try? Data(contentsOf: gifURL),
              let source = CGImageSourceCreateWithData(gifData as CFData, nil) else {
            print("Failed to load GIF")
            return nil
        }

        var frames: [(UIImage, Double)] = []
        let frameCount = CGImageSourceGetCount(source)

        for i in 0..<frameCount {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let duration = frameDuration(source: source, index: i)
                let uiImage = UIImage(cgImage: cgImage)
                frames.append((uiImage, duration))
            }
        }

        return frames
    }

    static func frameDuration(source: CGImageSource, index: Int) -> Double {
        let frameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any]
        let gifProperties = frameProperties?[kCGImagePropertyGIFDictionary as String] as? [String: Any]
        let duration = gifProperties?[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double ??
                       gifProperties?[kCGImagePropertyGIFDelayTime as String] as? Double ?? 0.1
        
       
        return max(duration, 0.01) // Avoid zero-duration frames
    }
}
