//
//  AppState.swift
//  fw_note
//
//  Created by Fung Wing on 2/4/2025.
//


import PDFKit
import PencilKit
import SwiftUI

class AppState {

    static func getImageDirectory() -> URL? {
        let appSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let imageDirectory = appSupportDirectory.appendingPathComponent(
            "fw_notes_images", isDirectory: true)
        
        // Ensure the directory exists
        if !FileManager.default.fileExists(atPath: imageDirectory.path) {
            do {
                try FileManager.default.createDirectory(
                    at: imageDirectory, withIntermediateDirectories: true,
                    attributes: nil)
            } catch {
                print("Failed to create directory: \(error)")
                return nil
            }
        }
        
        return imageDirectory
    }
   
 
}
