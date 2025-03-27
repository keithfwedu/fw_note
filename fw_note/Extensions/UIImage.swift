//
//  UIImage.swift
//  fw_note
//
//  Created by Fung Wing on 27/3/2025.
//

import UIKit

extension UIImage {
    static func animatedImage(withAnimatedGIFData data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        let frameCount = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        var totalDuration: TimeInterval = 0

        for i in 0..<frameCount {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                frames.append(UIImage(cgImage: cgImage))
            }

            // Retrieve the exact frame duration from GIF metadata
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any],
               let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any],
               let frameDuration = gifProperties[kCGImagePropertyGIFDelayTime] as? NSNumber {
                totalDuration += frameDuration.doubleValue
            }
        }

        // Generate the animated UIImage with accurate frame durations
        return UIImage.animatedImage(with: frames, duration: totalDuration)
    }
}

