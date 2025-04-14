//
//  FileHelper.swift
//  fw_note
//
//  Created by Fung Wing on 3/4/2025.
//

import CoreData
import PDFKit
import SwiftUI

class FileHelper {

    static func updateFreeSpace() -> Double {
        if let attributes = try? FileManager.default.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        ),
            let freeSpace = attributes[.systemFreeSize] as? Double,
            let totalSpace = attributes[.systemSize] as? Double
        {
            return freeSpace / totalSpace
        }

        return 0.0
    }

    static func getBaseDirectory() -> URL {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
    }

    static func getPDFPath(projectId: UUID) -> String {
        let currentUserId = getCurrentUserId()

        // Get the path to the Documents directory
        let baseDirectory = getBaseDirectory()

        let projectDirectory = baseDirectory.appendingPathComponent(
            "users/\(currentUserId)/projects/\(projectId.uuidString)",
            isDirectory: true
        )

        let pdfPath = projectDirectory.appendingPathComponent(
            "source.pdf"
        )

        return pdfPath.path
    }

    static func getThumbnailData(projectId: UUID) -> UIImage? {
        let currentUserId = getCurrentUserId()

        // Get the path to the Documents directory
        let baseDirectory = getBaseDirectory()

        let projectDirectory = baseDirectory.appendingPathComponent(
            "users/\(currentUserId)/projects/\(projectId.uuidString)",
            isDirectory: true
        )

        let thumbnailPath = projectDirectory.appendingPathComponent(
            "thumbnail.jpg"
        )

        //read image from path
        if FileManager.default.fileExists(atPath: thumbnailPath.path) {
            let data = try! Data(contentsOf: thumbnailPath)
            return UIImage(data: data)!
        } else {
            return nil
        }

    }

    static func getCurrentUserId() -> String {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<AppState> = AppState.fetchRequest()

        do {
            if let appState = try context.fetch(fetchRequest).first {
                return appState.currentUserId ?? "guest"  // Default to "guest" if nil
            } else {
                // Create a default AppState if none exists
                let newAppState = AppState(context: context)
                newAppState.currentUserId = "guest"

                try context.save()
                print("Default AppState created with currentUserId: guest")
                return "guest"
            }
        } catch {
            print("Failed to fetch or create AppState: \(error)")
            return "guest"
        }
    }

    static func ensureProjectDirectoriesExist() {
        // Retrieve the currentUserId from Core Data
        let currentUserId = getCurrentUserId()

        // Get the path to the Documents directory
        let documentsDirectory = getBaseDirectory()
        // Define the paths for "images" and "projects" directories
        let userDirectory = documentsDirectory.appendingPathComponent(
            "users/\(currentUserId)",
            isDirectory: true
        )
        let imagesDirectory = userDirectory.appendingPathComponent(
            "images",
            isDirectory: true
        )
        let projectsDirectory = userDirectory.appendingPathComponent(
            "projects",
            isDirectory: true
        )

        // Create directories if they do not exist
        let directories = [userDirectory, imagesDirectory, projectsDirectory]
        for directory in directories {
            if !FileManager.default.fileExists(atPath: directory.path) {
                do {
                    try FileManager.default.createDirectory(
                        at: directory,
                        withIntermediateDirectories: true
                    )
                    print("Directory created at path: \(directory.path)")
                } catch {
                    print(
                        "Failed to create directory at path \(directory.path): \(error)"
                    )
                }
            }
        }
    }

    static func createNewProject(pdfPathUrl: URL? = nil, title: String) {
        let projectId = UUID()

        let currentUserId = getCurrentUserId()
        let baseDirectory = getBaseDirectory()

        let projectDirectory = baseDirectory.appendingPathComponent(
            "users/\(currentUserId)/projects/\(projectId.uuidString)",
            isDirectory: true
        )
        let imagesDirectory = projectDirectory.appendingPathComponent(
            "images",
            isDirectory: true
        )
        // Define paths for source.pdf and thumbnail.jpg
        let sourcePdfPath = projectDirectory.appendingPathComponent(
            "source.pdf"
        )
        let thumbnailPath = projectDirectory.appendingPathComponent(
            "thumbnail.jpg"
        )

        let dataPath = projectDirectory.appendingPathComponent(
            "data.json"
        )

        // Construct the JSON file path

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        let directories = [projectDirectory, imagesDirectory]
        for directory in directories {
            if !FileManager.default.fileExists(atPath: directory.path) {
                // Ensure the project directory exists
                do {
                    try FileManager.default.createDirectory(
                        at: directory,
                        withIntermediateDirectories: true
                    )
                    print(
                        "Project directory created at: \(directory.path)"
                    )
                } catch {
                    print("Failed to create project directory: \(error)")
                    return
                }
            }
        }
        if pdfPathUrl != nil {
            // Step 1: Copy PDF to the project directory
            do {
                try FileManager.default.copyItem(
                    at: pdfPathUrl!,
                    to: sourcePdfPath
                )
                print("PDF copied to: \(sourcePdfPath.path)")
            } catch {
                print("Failed to copy PDF: \(error)")
                return
            }
        } else {
            createPDF(pdfPath: sourcePdfPath)
        }

        do {
            let noteFile = NoteFile(id: projectId, title: title)
            // Encode the NoteFile object to JSON data
            let jsonData = try encoder.encode(noteFile)

            // Write JSON data to the file
            try jsonData.write(to: dataPath)
            print("Metadata saved to: \(dataPath)")

        } catch {
            // Handle errors and print meaningful messages
            print("Error saving metadata to \(dataPath): \(error)")

        }

        // Step 2: Generate thumbnail from the first page of the PDF
        generateThumbnail(from: sourcePdfPath, saveTo: thumbnailPath)
    }

    // Function to save NoteFile to data.json
    static func saveProject(noteFile: NoteFile) {
        let currentUserId = getCurrentUserId()  // Fetch the current user ID
        let baseDirectory = getBaseDirectory()  // Base directory of your app
        let projectId = noteFile.id
        // Define the project and images directories
        let projectDirectory = baseDirectory.appendingPathComponent(
            "users/\(currentUserId)/projects/\(projectId.uuidString)",
            isDirectory: true
        )
        let dataPath = projectDirectory.appendingPathComponent("data.json")

        // Create a JSONEncoder and configure it for pretty printing
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            // Encode the NoteFile object to JSON data
            let jsonData = try encoder.encode(noteFile)

            // Write the JSON data to the file
            try jsonData.write(to: dataPath)
            print("NoteFile metadata saved to: \(dataPath.path)")
        } catch {
            // Handle errors during encoding or writing
            print("Error saving NoteFile to \(dataPath.path): \(error)")
        }
    }

    static func getImageDirectory() -> URL? {
        let currentUserId = getCurrentUserId()  // Fetch the current user ID
        let baseDirectory = getBaseDirectory()
        let imagesDirectory = baseDirectory.appendingPathComponent(
            "users/\(currentUserId)/images",
            isDirectory: true
        )

        guard FileManager.default.fileExists(atPath: imagesDirectory.path)
        else {
            print("data.json file not found at path: \(imagesDirectory.path)")
            return nil
        }
        return imagesDirectory
    }

    static func getNoteFile(projectId: UUID) -> NoteFile? {
        let currentUserId = getCurrentUserId()  // Fetch the current user ID
        let baseDirectory = getBaseDirectory()  // Base directory of your app

        // Define the path to the data.json file within the project directory
        let dataPath = baseDirectory.appendingPathComponent(
            "users/\(currentUserId)/projects/\(projectId.uuidString)/data.json"
        )

        // Check if the data.json file exists
        guard FileManager.default.fileExists(atPath: dataPath.path) else {
            print("data.json file not found at path: \(dataPath.path)")
            return nil
        }

        do {
            // Read the JSON data from the file
            let jsonData = try Data(contentsOf: dataPath)

            // Decode the JSON data into a NoteFile object
            let decoder = JSONDecoder()
            let noteFile = try decoder.decode(NoteFile.self, from: jsonData)
            print("NoteFile metadata read successfully: \(noteFile)")
            return noteFile
        } catch {
            // Handle errors during file reading or decoding
            print("Error reading NoteFile from \(dataPath.path): \(error)")
            return nil
        }
    }

    static func getUserImageFilePath(imageName: String, projectId: UUID)
        -> String?
    {
        let currentUserId = getCurrentUserId()  // Fetch the current user ID
        let baseDirectory = getBaseDirectory()  // Base directory of your app
        // Define the project and images directories

        let imagesDirectory = baseDirectory.appendingPathComponent(
            "users/\(currentUserId)/images",
            isDirectory: true
        )

        return imagesDirectory.appendingPathComponent(imageName).path
    }

    static func getProjectImageFilePath(imageName: String, projectId: UUID)
        -> String?
    {
        let currentUserId = getCurrentUserId()  // Fetch the current user ID
        let baseDirectory = getBaseDirectory()  // Base directory of your app
        // Define the project and images directories
        let projectDirectory = baseDirectory.appendingPathComponent(
            "users/\(currentUserId)/projects/\(projectId.uuidString)",
            isDirectory: true
        )
        let imagesDirectory = projectDirectory.appendingPathComponent(
            "images",
            isDirectory: true
        )

        return imagesDirectory.appendingPathComponent(imageName).path
    }

    static func copyImageToProject(imagePath: String, projectId: UUID)
        -> String?
    {
        let currentUserId = getCurrentUserId()  // Fetch the current user ID
        let baseDirectory = getBaseDirectory()  // Base directory of your app

        let userDirectory = baseDirectory.appendingPathComponent(
            "users/\(currentUserId)",
            isDirectory: true
        )
        let userImagesDirectory = userDirectory.appendingPathComponent(
            "images",
            isDirectory: true
        )

        // Define the project and images directories
        let projectDirectory = baseDirectory.appendingPathComponent(
            "users/\(currentUserId)/projects/\(projectId.uuidString)",
            isDirectory: true
        )
        let imagesDirectory = projectDirectory.appendingPathComponent(
            "images",
            isDirectory: true
        )

        // Ensure the images directory exists
        do {
            if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
                try FileManager.default.createDirectory(
                    at: imagesDirectory,
                    withIntermediateDirectories: true
                )
                print("Images directory created at: \(imagesDirectory.path)")
            }
        } catch {
            print("Failed to create images directory: \(error)")
            return nil
        }

        let absoluteImagePath = userImagesDirectory.appendingPathComponent(
            imagePath
        )
        // Define the destination path for the image
        let imageFileName = absoluteImagePath.lastPathComponent  // Extract file name from the source path

        let destinationPath = imagesDirectory.appendingPathComponent(
            imageFileName
        )

        print("Source URL: \(absoluteImagePath)")
        print("Destination URL: \(destinationPath)")

        // Check if the image already exists at the destination path
        if FileManager.default.fileExists(atPath: destinationPath.path) {
            print("Image already exists at: \(destinationPath.path)")
            return imageFileName  // Return existing file name
        }

        // Copy the image to the destination path
        do {
            try FileManager.default.copyItem(
                at: absoluteImagePath,
                to: destinationPath
            )
            print("Image copied to: \(destinationPath.path)")
            return imageFileName
        } catch {
            print("Failed to copy image: \(error)")
            return nil
        }
    }

    private static func generateThumbnail(
        from pdfUrl: URL,
        saveTo thumbnailPath: URL
    ) {
        guard let pdfDocument = PDFDocument(url: pdfUrl) else {
            print("Failed to open PDF document.")
            return
        }

        // Get the first page of the PDF
        guard let pdfPage = pdfDocument.page(at: 0) else {
            print("Failed to get the first page of the PDF.")
            return
        }

        // Render the first page to an image

        let originalSize = pdfPage.bounds(for: .mediaBox).size
        let thumbnail = pdfPage.thumbnail(of: originalSize, for: .mediaBox)

        // Save the image as a JPEG file
        if let jpegData = thumbnail.jpegData(compressionQuality: 0.8) {
            do {
                try jpegData.write(to: thumbnailPath)
                print("Thumbnail saved to: \(thumbnailPath.path)")
            } catch {
                print("Failed to save thumbnail: \(error)")
            }
        }
    }

    static func listProjects() -> [NoteFile] {

        // Get the base path for the project directory
        let currentUserId = getCurrentUserId()
        let baseDirectory = getBaseDirectory()
        let projectsDirectory = baseDirectory.appendingPathComponent(
            "users/\(currentUserId)/projects",
            isDirectory: true
        )

        var noteFiles: [NoteFile] = []
        let decoder = JSONDecoder()

        do {
            let subdirectories = try FileManager.default.contentsOfDirectory(
                at: projectsDirectory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )

            noteFiles = subdirectories.compactMap { directory in
                let jsonFileURL = directory.appendingPathComponent("data.json")
                guard FileManager.default.fileExists(atPath: jsonFileURL.path)
                else {
                    print("Skipping: No data.json found in \(directory).")
                    return nil
                }

                do {
                    let data = try Data(contentsOf: jsonFileURL)
                    return try decoder.decode(NoteFile.self, from: data)
                } catch {
                    print(
                        "Error decoding JSON file at \(jsonFileURL): \(error)"
                    )
                    return nil
                }
            }
        } catch {
            print(
                "Error reading contents of notes directory \(projectsDirectory): \(error)"
            )
        }

        return noteFiles
    }

    static func deleteProject(projectId: String) {
        let currentUserId = getCurrentUserId()
        let baseDirectory = getBaseDirectory()

        // Construct the path to the project directory
        let projectDirectory = baseDirectory.appendingPathComponent(
            "users/\(currentUserId)/projects/\(projectId)",
            isDirectory: true
        )

        // Check if the directory exists
        if FileManager.default.fileExists(atPath: projectDirectory.path) {
            do {
                // Attempt to remove the directory and its contents
                try FileManager.default.removeItem(at: projectDirectory)
                print("Project directory deleted: \(projectDirectory.path)")
            } catch {
                print("Failed to delete project directory: \(error)")
            }
        } else {
            print(
                "Project directory does not exist at path: \(projectDirectory.path)"
            )
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
        let relativePath = String(
            fullPathString.dropFirst(basePathString.count)
        )

        // Remove leading "/" if present
        return relativePath.hasPrefix("/")
            ? String(relativePath.dropFirst()) : relativePath
    }

    static func getAbsoluteProjectPath(userId: String, relativePath: String)
        -> URL?
    {
        let baseDirectory = getBaseDirectory()
        return baseDirectory.appendingPathComponent(relativePath)
        //.deletingLastPathComponent()
    }

    static func createPDF(pdfPath: URL) {
        let dpi: CGFloat = 72
        let a4WidthInInches: CGFloat = 8.27  // A4 width in inches
        let a4HeightInInches: CGFloat = 11.69  // A4 height in inches
        let pdfPageSize = CGSize(
            width: a4WidthInInches * dpi,
            height: a4HeightInInches * dpi
        )

        // Create a new PDF context
        UIGraphicsBeginPDFContextToFile(
            pdfPath.path,
            CGRect(origin: .zero, size: pdfPageSize),
            nil
        )
        // Start a new page
        UIGraphicsBeginPDFPage()

        // Close the PDF context
        UIGraphicsEndPDFContext()
    }

}
