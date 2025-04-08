//
//  ImageHelper.swift
//  fw_note
//
//  Created by Fung Wing on 2/4/2025.
//

import SwiftUI
import UIKit
import Photos
import ImageIO
import MobileCoreServices
import UniformTypeIdentifiers

class ImageHelper {

    static func isGIF(filePath: String) -> Bool {
        // Read the data from the file at the given path
        guard
            let fileData = try? Data(contentsOf: URL(fileURLWithPath: filePath))
        else {
            print("Failed to load file at path: \(filePath)")
            return false
        }

        return isGIF(data: fileData)
    }

    // Detect whether the data represents a GIF
    static func isGIF(data: Data) -> Bool {
        let gifHeader: [UInt8] = [0x47, 0x49, 0x46, 0x38]  // "GIF8" magic number
        let dataHeader = [UInt8](data.prefix(gifHeader.count))
        return dataHeader == gifHeader
    }

    static func resizeImage(_ image: UIImage, to newSize: CGFloat = 500)
        -> UIImage
    {
        let resizedImage: UIImage
        if image.size.width > newSize || image.size.height > newSize {
            let maxDimension: CGFloat = newSize
            let aspectRatio = image.size.width / image.size.height

            let newSize: CGSize
            if aspectRatio > 1 {
                newSize = CGSize(
                    width: maxDimension,
                    height: maxDimension / aspectRatio)
            } else {
                newSize = CGSize(
                    width: maxDimension * aspectRatio,
                    height: maxDimension)
            }

            print("newSize: \(newSize)")

            UIGraphicsBeginImageContextWithOptions(
                newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            resizedImage =
                UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            print("No newSize: \(image.size)")
            resizedImage = image  // No resize needed
        }

        return resizedImage
    }

    static func resizeGIF(_ gifData: Data, to newSize: CGFloat = 200) -> Data? {
        guard let source = CGImageSourceCreateWithData(gifData as CFData, nil)
        else {
            print("Failed to create CGImageSource.")
            return nil
        }

        let frameCount = CGImageSourceGetCount(source)
        let newGIFData = NSMutableData()

        // Set up GIF destination
        guard
            let destination = CGImageDestinationCreateWithData(
                newGIFData, UTType.gif.identifier as CFString, frameCount, nil)
        else {
            print("Failed to create GIF destination.")
            return nil
        }

        // Loop through each frame
        for i in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil),
                let frameProperties = CGImageSourceCopyPropertiesAtIndex(
                    source, i, nil) as? [CFString: Any],
                let gifFrameProperties = frameProperties[
                    kCGImagePropertyGIFDictionary] as? [CFString: Any]
            else {
                continue
            }

            // Preserve frame delay time
            let delayTime =
                gifFrameProperties[kCGImagePropertyGIFDelayTime] as? Double
                ?? 0.1

            let originalWidth = CGFloat(cgImage.width)
            let originalHeight = CGFloat(cgImage.height)
            let aspectRatio = originalWidth / originalHeight

            // Compute the new size
            let newSizeDimensions: CGSize
            if aspectRatio > 1 {
                newSizeDimensions = CGSize(
                    width: newSize, height: newSize / aspectRatio)
            } else {
                newSizeDimensions = CGSize(
                    width: newSize * aspectRatio, height: newSize)
            }

            // Resize the frame
            UIGraphicsBeginImageContextWithOptions(
                newSizeDimensions, false, 1.0)
            UIImage(cgImage: cgImage).draw(
                in: CGRect(origin: .zero, size: newSizeDimensions))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            // Add resized frame to the new GIF with preserved frame properties
            if let resizedCGImage = resizedImage?.cgImage {
                let newFrameProperties: [CFString: Any] = [
                    kCGImagePropertyGIFDictionary: [
                        kCGImagePropertyGIFDelayTime: delayTime  // Set the frame delay
                    ]
                ]
                CGImageDestinationAddImage(
                    destination, resizedCGImage,
                    newFrameProperties as CFDictionary)
            }
        }

        // Set GIF-level properties (loop count)
        let gifProperties: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: nil  // Infinite looping
            ]
        ]
        CGImageDestinationSetProperties(
            destination, gifProperties as CFDictionary)

        // Finalize the new GIF
        if !CGImageDestinationFinalize(destination) {
            print("Failed to finalize the GIF.")
            return nil
        }

        print("Resized GIF with loop count set to infinite (0).")
        return newGIFData as Data
    }
    
    
    static func handleGIFWithUUID(input: String, completion: @escaping (String?) -> Void) {
        guard let uuid = parseUUID(from: input) else {
            print("Failed to parse UUID from input: \(input)")
            completion(nil)
            return
        }

        fetchGIFByUUID(uuid: uuid) { gifData in
            guard let gifData = gifData else {
                print("Failed to fetch GIF for UUID: \(uuid)")
                completion(nil)
                return
            }

            if let path = saveGIFImage(imageData: gifData) {
                print("GIF successfully saved at: \(path)")
                completion(path)
            } else {
                completion(nil)
            }
        }
    }

    
    static func parseUUID(from input: String) -> String? {
        // Extract only the filename portion from the path, if necessary
        let fileName = input.components(separatedBy: "/").last ?? input

        // Split the filename by "&" and find the component that starts with "uuid="
        let components = fileName.split(separator: "&")
        for component in components {
            if component.starts(with: "uuid=") {
                return String(component.dropFirst(5)) // Remove the "uuid=" prefix
            }
        }
        return nil
    }


    static func fetchGIFByUUID(uuid: String, completion: @escaping (Data?) -> Void) {
        // Request access to the Photos library
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Photos access denied.")
                completion(nil)
                return
            }
            
            // Fetch assets by UUID
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "localIdentifier CONTAINS %@", uuid)
            
            let assets = PHAsset.fetchAssets(with: fetchOptions)
            guard let asset = assets.firstObject else {
                print("No asset found for UUID: \(uuid)")
                completion(nil)
                return
            }
            
            // Request the GIF data
            let manager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .highQualityFormat
            
            manager.requestImageDataAndOrientation(for: asset, options: requestOptions) { data, orientation, info, arg  in
                completion(data)
            }
        }
    }


    static func saveGIFImage(imageData: Data) -> String? {
        do {
            let imageDirectory = FileHelper.getImageDirectory()
            let fileName = UUID().uuidString + ".gif"
            guard let fileURL = imageDirectory?.appendingPathComponent(fileName)
            else {
                print("Error get fileURL")
                return nil
            }

            try imageData.write(to: fileURL)
            print("GIF saved successfully at \(fileURL)")
            let relativePath: String = URL(fileURLWithPath: fileURL.path)
                .lastPathComponent
            return relativePath
        } catch {
            print("Error saving image: \(error.localizedDescription)")
            return nil
        }
    }

    static func saveStaticImage(imageData: Data) -> String? {
        do {
            let imageDirectory = FileHelper.getImageDirectory()
            let fileName = UUID().uuidString + ".png"
            guard let fileURL = imageDirectory?.appendingPathComponent(fileName)
            else {
                print("Error get fileURL")
                return nil
            }

            // Load the original image from Data
            guard let originalImage = UIImage(data: imageData) else {
                throw NSError(
                    domain: "ImageError", code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Unable to load UIImage from Data."
                    ])
            }

            // Resize the image
            let resizedImage = resizeImage(originalImage, to: 500)

            // Save the resized image
            guard let resizedImageData = resizedImage.pngData() else {
                throw NSError(
                    domain: "ImageResizeError", code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Failed to convert resized UIImage to PNG Data."
                    ])
            }
            try resizedImageData.write(to: fileURL)
            print("Resized PNG saved successfully at \(fileURL)")
            let relativePath: String = URL(fileURLWithPath: fileURL.path)
                .lastPathComponent
            return relativePath
        } catch {
            print("Error saving image: \(error.localizedDescription)")
            return nil
        }
    }

    static func checkPhotoLibraryPermission(
        completion: @escaping (Bool) -> Void
    ) {
        let status = PHPhotoLibrary.authorizationStatus()

        switch status {
        case .authorized:
            // Permission already granted
            completion(true)
        case .limited:
            // Permission granted, but with limited access
            completion(true)
        case .notDetermined:
            // Request permission
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(
                        newStatus == .authorized || newStatus == .limited)
                }
            }
        case .denied, .restricted:
            // Permission denied or restricted
            completion(false)
        @unknown default:
            completion(false)
        }
    }

}
