import ImageIO
import UIKit
import UniformTypeIdentifiers // Use MobileCoreServices for iOS 13 or earlier

class GIFDecoder {
    /// Decodes the frames of a GIF into a sequence of UIImage and their respective durations.
    static func decodeGIF(from path: String, targetSize: CGSize? = nil) -> [(UIImage, Double)]? {
        let gifURL = URL(fileURLWithPath: path)
        guard let gifData = try? Data(contentsOf: gifURL),
              let source = CGImageSourceCreateWithData(gifData as CFData, nil) else {
            print("Failed to load GIF from path: \(path)")
            return nil
        }

        var frames: [(UIImage, Double)] = []
        let frameCount = CGImageSourceGetCount(source)

        if frameCount == 0 {
            print("No frames found in GIF.")
            return nil
        }

        for i in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else {
                print("Failed to create CGImage for frame \(i).")
                continue
            }

            let duration = frameDuration(source: source, index: i)

            // Create UIImage (non-optional)
            let uiImage = UIImage(cgImage: cgImage)

            // Resize the frame if a target size is provided
            if let targetSize = targetSize {
                if let resizedImage = resizeImage(uiImage, targetSize: targetSize) {
                    frames.append((resizedImage, duration))
                } else {
                    print("Failed to resize frame \(i).")
                }
            } else {
                frames.append((uiImage, duration))
            }
        }

        return frames
    }


    /// Calculates the duration for a specific frame in the GIF.
    static func frameDuration(source: CGImageSource, index: Int) -> Double {
        let frameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any]
        let gifProperties = frameProperties?[kCGImagePropertyGIFDictionary as String] as? [String: Any]
        let duration = gifProperties?[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double ??
                       gifProperties?[kCGImagePropertyGIFDelayTime as String] as? Double ?? 0.1

        return max(duration, 0.01) // Avoid zero-duration frames
    }

    /// Resizes a UIImage to the specified size.
    static func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    /// Compresses the frames of a GIF and saves a new compressed GIF to the specified output path.
    static func createCompressedGIF(frames: [(UIImage, Double)], outputPath: String, targetSize: CGSize? = nil) {
        let outputURL = URL(fileURLWithPath: outputPath)
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.gif.identifier as CFString, frames.count, nil) else {
            print("Failed to create GIF destination at: \(outputPath)")
            return
        }

        let properties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0 // Infinite loop
            ]
        ]
        CGImageDestinationSetProperties(destination, properties as CFDictionary)

        for (image, duration) in frames {
            let resizedImage = targetSize != nil ? resizeImage(image, targetSize: targetSize!) : image
            guard let cgImage = resizedImage?.cgImage else { continue }

            let frameProperties: [String: Any] = [
                kCGImagePropertyGIFDictionary as String: [
                    kCGImagePropertyGIFDelayTime as String: duration
                ]
            ]
            CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
        }

        if CGImageDestinationFinalize(destination) {
            print("Compressed GIF successfully created at: \(outputPath)")
        } else {
            print("Failed to finalize the compressed GIF.")
        }
    }
}
