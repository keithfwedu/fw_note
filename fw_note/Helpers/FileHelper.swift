//
//  FileHelper.swift
//  fw_note
//
//  Created by Fung Wing on 3/4/2025.
//

import SwiftUI

class FileHelper {
    static func getBaseDirectory() -> URL {
        return FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
    }
    
    static func getImageDirectory() -> URL? {
        let baseDirectory = FileHelper.getBaseDirectory()
        let imageDirectory = subDirectory(baseDirectory: baseDirectory, subDirectoryPath: "images")
        return imageDirectory
    }

    static func getProjectDirectory() -> URL? {
        let baseDirectory = FileHelper.getBaseDirectory()
        let projectDirectory = subDirectory(baseDirectory: baseDirectory, subDirectoryPath: "projects")
        return projectDirectory
    }

    static func getProjectDirectory(userId: String) -> URL? {
        guard let projectDirectory = getProjectDirectory() else {
            return nil
        }
        
        guard let userProjectDirectory = subDirectory(baseDirectory: projectDirectory, subDirectoryPath: userId) else {
            return nil
        }
        
        return userProjectDirectory
    }

    static func getNoteDirectory(userId: String = "guest", noteId: String) -> URL? {
        guard let projectDirectory = getProjectDirectory(userId: userId),
              let pdfDirectory = subDirectory(baseDirectory: projectDirectory, subDirectoryPath: noteId) else {
            return nil
        }
        return pdfDirectory
    }
    
    static func listProjects(userId: String) -> [NoteFile] {
        guard let notesDirectory = getProjectDirectory(userId: userId) else {
            print("Error: Failed to get notes directory for user ID \(userId).")
            return []
        }

        var noteFiles: [NoteFile] = []
        let decoder = JSONDecoder()

        do {
            let subdirectories = try FileManager.default.contentsOfDirectory(
                at: notesDirectory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )

            noteFiles = subdirectories.compactMap { directory in
                let jsonFileURL = directory.appendingPathComponent("data.json")
                guard FileManager.default.fileExists(atPath: jsonFileURL.path) else {
                    print("Skipping: No data.json found in \(directory).")
                    return nil
                }

                do {
                    let data = try Data(contentsOf: jsonFileURL)
                    return try decoder.decode(NoteFile.self, from: data)
                } catch {
                    print("Error decoding JSON file at \(jsonFileURL): \(error)")
                    return nil
                }
            }
        } catch {
            print("Error reading contents of notes directory \(notesDirectory): \(error)")
        }

        return noteFiles
    }
    
    static func newNote(userId: String, pdfPathUrl: URL) {
        // Generate a unique directory path for the note
        let noteId = UUID()
        let pdfFileName = pdfPathUrl.lastPathComponent
        let pdfFilePath = FileHelper.savePDFtoProject(userId: userId, noteId: noteId.uuidString, pdfFileUrl: pdfPathUrl)

        // Create the NoteFile object
        let noteFile = NoteFile(
            id: noteId,
            title: "New Note \(Date().description)", // Generate a unique title
            pdfFilePath: pdfFilePath
        )

        newMetaDataFile(userId: userId, noteId: noteId.uuidString, noteFile: noteFile)

    }

    static func deleteNote(userId: String, noteFile: NoteFile) {
      
      
        if let relativeNotePath = noteFile.pdfFilePath {
            guard let absoluteNotePath = getAbsoluteProjectPath(userId: userId, relativePath: relativeNotePath) else {
                return
            }

            guard FileManager.default.fileExists(atPath: absoluteNotePath.path) else {
                print("Project not found: \(absoluteNotePath.path)")
                return
            }

            do {
                try FileManager.default.removeItem(at: absoluteNotePath)
            } catch {
                print("Error deleting note at \(absoluteNotePath.path): \(error)")
            }
        }

    }
    
    static func newMetaDataFile(userId: String, noteId: String, noteFile: NoteFile) -> URL? {
        guard let noteDirectory = getNoteDirectory(userId: userId, noteId: noteId) else {
            print("Error: Failed to get note directory for user ID \(userId) and note ID \(noteId).")
            return nil
        }

        // Construct the JSON file path
        let jsonFileURL = noteDirectory.appendingPathComponent("data.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            // Encode the NoteFile object to JSON data
            let jsonData = try encoder.encode(noteFile)
            
            // Write JSON data to the file
            try jsonData.write(to: jsonFileURL)
            print("Metadata saved to: \(jsonFileURL)")
            return jsonFileURL
        } catch {
            // Handle errors and print meaningful messages
            print("Error saving metadata to \(jsonFileURL): \(error)")
            return nil
        }
    }

    
    static func savePDFtoProject(userId: String, noteId: String, pdfFileUrl: URL) -> String? {
        let pdfFileName = pdfFileUrl.lastPathComponent

        // Safely unwrap the optional noteUrl returned by getNoteDirectory
        guard let noteUrl = getNoteDirectory(userId: userId, noteId: noteId) else {
            print("Error: Failed to get note directory for user ID \(userId) and note ID \(noteId).")
            return nil
        }

        let noteFileUrl = noteUrl.appendingPathComponent(pdfFileName)

        do {
            // Use try to handle errors thrown by copyItem
            try FileManager.default.copyItem(at: pdfFileUrl, to: noteFileUrl)
            let relativePath = getRelativePath(from: noteFileUrl);
            return relativePath;
        } catch {
            print("Error copying PDF file to \(noteFileUrl): \(error)")
            return nil
        }
    }

    
    static func getRelativePath(from url: URL) -> String? {
        let basePathString = getBaseDirectory().path
        let fullPathString = url.path

        // Validate that the fullPathString starts with basePathString
        guard fullPathString.hasPrefix(basePathString) else {
            print("Error: Full path does not start with the base path.")
            return nil
        }

        // Drop the base path part to get the relative path
        let relativePath = String(fullPathString.dropFirst(basePathString.count))
        
        // Remove leading "/" if present
        return relativePath.hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath
    }

    
    static func getAbsoluteProjectPath(userId: String, relativePath: String) -> URL? {
        guard let projectsDirectory = getProjectDirectory(userId: userId) else {
            print("Error: Failed to get notes directory for user ID \(userId).")
            return nil
        }
       return projectsDirectory.appendingPathComponent(relativePath).deletingLastPathComponent()
    }

    static func subDirectory(baseDirectory: URL, subDirectoryPath: String) -> URL? {
        let subDirectory = baseDirectory.appendingPathComponent(subDirectoryPath, isDirectory: true)

        // Ensure the subdirectory exists
        do {
            try createDirectoryIfNotExist(subDirectory)
        } catch {
            print("Failed to create subdirectory \(subDirectory): \(error)")
            return nil
        }

        return subDirectory
    }


    // Ensure directory creation for any path
    static func createDirectoryIfNotExist(_ directory: URL) throws {
        if !FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true, // This ensures all intermediate paths are created
                    attributes: nil
                )
            } catch {
                print("Failed to create directory: \(error)")
                throw error
            }
        }
    }

}
