//
//  ImagePickerView.swift
//  fw_note
//
//  Created by Fung Wing on 25/3/2025.
//

import SwiftUI

struct ImagePickerView: View {

    @State private var images: [UIImage] = []
    @State private var imagePaths: [String] = []  // Paths for persistence
    @State private var isShowingImagePicker = false
    @State private var isShowingPopover = false
    @State private var selectedSourceType: UIImagePickerController.SourceType =
        .photoLibrary
    @State private var isLoading = false
    @ObservedObject var noteFile: NoteFile
    @ObservedObject var canvasState: CanvasState
    let appSupportDirectory = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask
    ).first!

    let onClose: () -> Void

    var body: some View {
        VStack {
            // Top bar with Add and Close buttons
            HStack {
                Button(action: {
                    onClose()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                }

                Spacer()
                Button(action: {
                    isShowingPopover = true  // Show popover
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }.popover(isPresented: $isShowingPopover) {
                    VStack {
                        Button("Add from Gallery") {
                            selectedSourceType = .photoLibrary
                            isShowingPopover = false
                            isShowingImagePicker = true
                        }
                        Divider()
                        Button("Take Photo") {
                            selectedSourceType = .camera
                            isShowingPopover = false
                            isShowingImagePicker = true
                        }
                    }
                    .padding()

                }

            }
            .padding()
            let columns = [GridItem(.flexible()), GridItem(.flexible())]

            // Image display area
            ZStack {
                ScrollView {
                    LazyVGrid(
                        columns: columns

                    ) {
                        ForEach($imagePaths, id: \.self) { path in
                            ZStack {
                                if FileManager.default.fileExists(
                                    atPath: path.wrappedValue)
                                {
                                    MetalImageView(
                                        imagePath: path.wrappedValue,
                                        targetSize: CGSize(
                                            width: 100, height: 100)
                                    )
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                                    .onTapGesture {
                                        addImageToStack(path: path.wrappedValue)
                                    }
                                } else {
                                    Text("File Missing")
                                        .foregroundColor(.red)
                                        .frame(width: 100, height: 100)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(10)
                                }

                                Button(action: {
                                    removeImage(path.wrappedValue)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .padding(5)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                .offset(x: 30, y: -30)
                            }
                        }
                    }
                    .padding(10)  // Add padding around the grid
                }

                if isLoading {
                    Color.black.opacity(0.5)  // Dim background for better focus
                        .ignoresSafeArea()
                    ProgressView("Loading...")
                        .padding()
                }
            }
        }
        .background(Color(UIColor.systemGray5))
        .onDrop(of: ["public.image"], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }

        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(sourceType: selectedSourceType) { image, path in
                if let image = image, let path = path {
                    saveImageFromFile(
                        image, originalFilePath: path.absoluteString)
                } else {
                    print("Failed to retrieve image or path.")
                }
            }
        }
        .onAppear {
            loadSavedImagePaths()
        }

    }

    private func getAndScaleImageSize(from path: String, maxDimension: CGFloat = 200) -> CGSize? {
        guard let image = UIImage(contentsOfFile: path) else {
            print("Failed to load image from path: \(path)")
            return nil
        }
        
        // Check if scaling is needed
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let aspectRatio = image.size.width / image.size.height

            // Calculate new size while maintaining the aspect ratio
            let newSize: CGSize
            if aspectRatio > 1 {
                // Width > Height
                newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
            } else {
                // Height >= Width
                newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
            }

            // Resize the image
            return newSize
        } else {
            // No scaling required
            return CGSize(width: 100, height: 100)
        }
    }

    // Helper function to resize the image
    private func resizeImage(_ image: UIImage, to newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage ?? image // Fallback to original image if resizing fails
    }


    private func addImageToStack(path: String? = nil) {
        // Ensure the path is not nil and the file exists at the given path
        guard let path = path, FileManager.default.fileExists(atPath: path)
        else {
            print("Error: Path does not exist or is nil")
            return
        }

        // Retrieve the image size from the file
        guard let imageSize = getAndScaleImageSize(from: path) else {
            print("Error: Unable to retrieve image size from path \(path)")
            return
        }

        // Calculate base position
        let pageIndex = canvasState.currentPageIndex
        let page = noteFile.notePages[pageIndex]

        let basePosition = page.pageCenterPoint
        let newPosition = CGPoint(x: basePosition.x, y: basePosition.y)

        // Create the ImageObj with the filtered and adjusted position
        let newImageObj = ImageObj(
            id: UUID(),
            path: path,
            position: newPosition,
            size: imageSize
        )

        // Create a new CanvasObj containing the ImageObj
        let newCanvasObj = CanvasObj(lineObj: nil, imageObj: newImageObj)

        // Add the new CanvasObj to the canvas stack
        noteFile.notePages[canvasState.currentPageIndex].canvasStack.append(
            newCanvasObj)

        // Add the operation to the undo stack
        noteFile.addToUndo(
            pageIndex: canvasState.currentPageIndex,
            canvasStack: noteFile.notePages[canvasState.currentPageIndex]
                .canvasStack
        )
    }

    private func saveImagePaths() {
        let appSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let uniqueDirectory = appSupportDirectory.appendingPathComponent(
            "fw_notes_images", isDirectory: true)

        // Ensure the directory exists
        if !FileManager.default.fileExists(atPath: uniqueDirectory.path) {
            do {
                try FileManager.default.createDirectory(
                    at: uniqueDirectory, withIntermediateDirectories: true,
                    attributes: nil)
            } catch {
                print("Failed to create directory: \(error)")
                return
            }
        }

        let relativePaths = imagePaths.map {
            URL(fileURLWithPath: $0).lastPathComponent
        }  // Extract relative file names
        let jsonFileURL = uniqueDirectory.appendingPathComponent(
            "imagePaths.json")

        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(relativePaths)
            try jsonData.write(to: jsonFileURL)
            print("Saved image paths to \(jsonFileURL.path)")
        } catch {
            print("Failed to save image paths: \(error)")
        }
    }

    // Load saved image paths
    private func loadSavedImagePaths() {
        let appSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let uniqueDirectory = appSupportDirectory.appendingPathComponent(
            "fw_notes_images", isDirectory: true)
        let jsonFileURL = uniqueDirectory.appendingPathComponent(
            "imagePaths.json")

        print("Loading image paths from \(jsonFileURL.path)")

        do {
            if FileManager.default.fileExists(atPath: jsonFileURL.path) {
                let data = try Data(contentsOf: jsonFileURL)
                let relativePaths = try JSONDecoder().decode(
                    [String].self, from: data)

                // Reconstruct full paths from relative paths
                imagePaths = relativePaths.map {
                    uniqueDirectory.appendingPathComponent($0).path
                }
                print("Loaded image paths: \(imagePaths)")
            } else {
                print("No image paths file found.")
                imagePaths = []
            }
        } catch {
            print("Failed to load image paths: \(error)")
        }
    }

    // Remove image
    private func removeImage(_ path: String) {
        imagePaths.removeAll { $0 == path }
        saveImagePaths()

        // Remove the file from disk
        let fileURL = URL(fileURLWithPath: path)
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("Removed file at \(fileURL)")
        } catch {
            print("Failed to remove file: \(error)")
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {

            // Check for a valid "public.image" type
            if provider.hasItemConformingToTypeIdentifier("public.image") {
                if provider.registeredTypeIdentifiers.contains(
                    "com.compuserve.gif")
                {
                    print("This item is a GIF")
                    provider.loadItem(
                        forTypeIdentifier: "com.compuserve.gif", options: nil
                    ) { item, error in
                        // Load the GIF Data directly

                        guard error == nil, let gifData = item as? Data else {
                        
                                print("Failed to load GIF: \(String(describing: error))")
                                return
                          
                        }
                        

                        do {
                            let imagesDirectory =
                                appSupportDirectory.appendingPathComponent(
                                    "fw_notes_images", isDirectory: true)
                            try FileManager.default.createDirectory(
                                at: imagesDirectory,
                                withIntermediateDirectories: true,
                                attributes: nil)
                            
                            let fileName = UUID().uuidString + ".gif"
                            let fileURL =
                                imagesDirectory.appendingPathComponent(
                                    fileName)
                            
                            try gifData.write(to: fileURL)
                            print("Gif Image saved at \(fileURL)")
                            saveImage(filePath: fileURL.path)
                        } catch {
                            print(
                                "Error saving GIF: \(error.localizedDescription)"
                            )
                        }

                    }

                } else {
                    // Handle other image formats
                    provider.loadObject(ofClass: UIImage.self) { item, error in
                        guard error == nil, let uiImage = item as? UIImage
                        else {
                            print(
                                "Failed to load image: \(String(describing: error))"
                            )
                            return
                        }
                        do {
                            let image = uiImage
                            let imagesDirectory =
                                appSupportDirectory.appendingPathComponent(
                                    "fw_notes_images", isDirectory: true)
                            try FileManager.default.createDirectory(
                                at: imagesDirectory,
                                withIntermediateDirectories: true,
                                attributes: nil)
                            let fileName = UUID().uuidString + ".png"
                            let fileURL =
                                imagesDirectory.appendingPathComponent(
                                    fileName)

                            let resizedImage = resizeImage(image)
                            let imageData = resizedImage.pngData()
                            try imageData?.write(to: fileURL)
                            print("Png Image saved at \(fileURL)")
                            saveImage(filePath: fileURL.path)

                        } catch {
                            print(
                                "Error processing image: \(error.localizedDescription)"
                            )
                        }

                    }
                }
            }
            return true  // Successfully handled the provider
        }
        return false  // No valid providers were processed
    }
    
    

    private func saveImageFromFile(_ image: UIImage, originalFilePath: String) {
        do {
            let fileExtension = (originalFilePath as NSString).pathExtension
                .lowercased()
            let imagesDirectory =
                appSupportDirectory.appendingPathComponent(
                    "fw_notes_images", isDirectory: true)
            try FileManager.default.createDirectory(
                at: imagesDirectory, withIntermediateDirectories: true,
                attributes: nil)

            if fileExtension == "gif" {
                // Save GIF directly
                let fileName = UUID().uuidString + ".gif"
                let fileURL = imagesDirectory.appendingPathComponent(
                    fileName)

                // Copy the original GIF file
                try FileManager.default.copyItem(
                    at: URL(fileURLWithPath: originalFilePath), to: fileURL)
                print("GIF saved at \(fileURL)")
                saveImage(filePath: fileURL.path)

            } else {
                // Handle other image types (e.g., resizing and saving as PNG)
                let fileName = UUID().uuidString + ".png"
                let fileURL = imagesDirectory.appendingPathComponent(
                    fileName)

                let resizedImage = resizeImage(image)
                let imageData = resizedImage.pngData()
                try imageData?.write(to: fileURL)
                print("Image saved at \(fileURL)")
                saveImage(filePath: fileURL.path)
            }

        } catch {
            isLoading = false
            print("Error handling file saveImage: \(error)")
        }

    }

    private func resizeImage(_ image: UIImage) -> UIImage {
        let resizedImage: UIImage
        if image.size.width > 500 || image.size.height > 500 {
            let maxDimension: CGFloat = 500
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

    // Save image paths for persistence
    private func saveImage(filePath: String) {

        DispatchQueue.global(qos: .background).async {

            isLoading = true

            // Determine the file type based on the original file path extension

            DispatchQueue.main.async {
                imagePaths.append(filePath)  // Save the new path
                saveImagePaths()  // Persist paths to a JSON file
                isLoading = false
            }

        }
    }

}
