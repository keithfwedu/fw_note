//
//  ImageState.swift
//  fw_note
//
//  Created by Fung Wing on 2/4/2025.
//

import PDFKit
import PencilKit
import SwiftUI

class ImageState: ObservableObject {
    @Published var images: [OriginalImageObj] = []
    
    func saveImageFromData(_ imageData: Data, isGif: Bool) -> OriginalImageObj? {
        var filePath:String? = nil
        var originalImageObj:OriginalImageObj? = nil
        if isGif {  // Custom helper function to check if the data is a GIF
            filePath = ImageHelper.saveGIFImage(imageData: imageData)
            originalImageObj = saveImage(filePath: filePath)
            
        } else {
            filePath = ImageHelper.saveStaticImage(imageData: imageData)
            originalImageObj = saveImage(filePath: filePath)
        }
        
        return originalImageObj
    }

    // Save image paths for persistence
    func saveImage(filePath: String?) -> OriginalImageObj? {
        guard let filePath = filePath else {
            print("Invalid file path for image")
            return nil
        }
        
        // Create the ImageObj with the filtered and adjusted position
        let newImageObj = OriginalImageObj(
            path: filePath
        )
        
       
        DispatchQueue.main.async {
            self.images.append(newImageObj)  // Save the new path
            self.persistImages()  // Persist paths to a JSON file
        }
        
        return newImageObj;
    }

    // Remove image
    func removeImage(_ originalImageObj: OriginalImageObj) {
        DispatchQueue.main.async {
            self.images.removeAll { $0.id == originalImageObj.id }
            self.persistImages()

        }
    }

    // Load saved image paths
    func loadImages() {
        guard let imageDirectory: URL = AppState.getImageDirectory() else {
            print("Failed to get image directory")
            return
        }
        let jsonFileURL = imageDirectory.appendingPathComponent(
            "images.json")

        print("Loading images from \(jsonFileURL.path)")

        do {
            if FileManager.default.fileExists(atPath: jsonFileURL.path) {
                let data = try Data(contentsOf: jsonFileURL)
                images = try JSONDecoder().decode(
                    [OriginalImageObj].self, from: data)
                print("Loaded image paths: \(images)")
            } else {
                print("No image paths file found.")
                images = []
            }
        } catch {
            print("Failed to load image paths: \(error)")
        }
    }

    func persistImages() {
        guard let imageDirectory: URL = AppState.getImageDirectory() else {
            print("Failed to get image directory")
            return
        }
        let jsonFileURL = imageDirectory.appendingPathComponent(
            "images.json")

        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(images)
            try jsonData.write(to: jsonFileURL)
            print("Saved image paths to \(jsonFileURL.path)")
        } catch {
            print("Failed to save image paths: \(error)")
        }
    }

}
