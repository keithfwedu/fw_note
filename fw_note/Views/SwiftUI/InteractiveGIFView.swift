//
//  InteractiveGIFView.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import SwiftUI

struct InteractiveGIFView: UIViewRepresentable {
    let gifName: String

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit

        // Load the GIF
        if let gifURL = Bundle.main.url(forResource: gifName, withExtension: "gif"),
           let gifData = try? Data(contentsOf: gifURL) {
            imageView.image = UIImage.gifImageWithData(gifData)
        }

        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        // No updates required for static GIFs
    }
}

// UIImage extension to handle GIF loading
extension UIImage {
    static func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        var images: [UIImage] = []
        var duration: TimeInterval = 0

        for i in 0..<CGImageSourceGetCount(source) {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any],
                   let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any],
                   let delayTime = gifProperties[kCGImagePropertyGIFDelayTime] as? NSNumber {
                    duration += delayTime.doubleValue
                }
            }
        }

        return UIImage.animatedImage(with: images, duration: duration)
    }
}
