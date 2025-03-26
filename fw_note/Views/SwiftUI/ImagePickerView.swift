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
    
    var body: some View {
        VStack {
            // Top bar with Add and Close buttons
               HStack {
                   Button(action: {
                       // Show popover logic
                       isShowingPopover = true
                   }) {
                       Image(systemName: "plus.circle")
                           .font(.system(size: 24))
                           .foregroundColor(.blue)
                   }
                   Spacer()
                   Button(action: {
                       // Close action logic
                       canvasState.showImagePicker = false
                   }) {
                       Image(systemName: "xmark.circle")
                           .font(.system(size: 24))
                           .foregroundColor(.red)
                   }
               }
               .padding()
            // Image display area
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 10)],
                    spacing: 10
                ) {
                    ForEach($imagePaths, id: \.self) { path in
                        ZStack {
                            if FileManager.default.fileExists(atPath: path.wrappedValue) {
                                MetalImageView(
                                    imagePath: path.wrappedValue,
                                    targetSize: CGSize(width: 100, height: 100)
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
                                Text("Not Exist")
                                    .frame(width: 100, height: 100)
                                    .background(Color.gray.opacity(0.2))
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
                .padding(10) // Add padding around the entire grid
            }

            if isLoading {
                ProgressView("Loading...")
                    .padding()
            }
        }
        .popover(isPresented: $isShowingPopover) {
            VStack {
                Button("Add from Gallery") {
                    selectedSourceType = .photoLibrary
                    isShowingImagePicker = true
                }
                Divider()
                Button("Take Photo") {
                    selectedSourceType = .camera
                    isShowingImagePicker = true
                }
            }
            .padding()
            .frame(width: 200, height: 100)
        }
        .fullScreenCover(isPresented: $isShowingImagePicker) {
            ImagePicker(sourceType: selectedSourceType) { image, path in
                if let image = image, let path = path {
                    saveImage(image, originalFilePath: path)
                } else {
                    print("Image or path is nil")
                }
            }
        }

        .onAppear {
            loadSavedImagePaths()
        }
    }

    // Add image to stack
    private func addImageToStack(path: String? = nil) {
        // Create the ImageObj with the file path
        let newImageObj = ImageObj(
            id: UUID(),
            path: path,  // Pass the file path here
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 100, height: 100)
        )

        // Create a new CanvasObj containing the ImageObj
        let newCanvasObj = CanvasObj();
        newCanvasObj.imageObj = newImageObj

        // Add the new CanvasObj to the canvas stack
        noteFile.notePages[canvasState.currentPageIndex].canvasStack.append(newCanvasObj)

        // Add the operation to the undo stack
        noteFile.addToUndo(
            pageIndex: canvasState.currentPageIndex,
            canvasStack: noteFile.notePages[canvasState.currentPageIndex].canvasStack
        )

      
    }


    // Save image paths for persistence
    private func saveImage(_ image: UIImage, originalFilePath: String) {
        DispatchQueue.global(qos: .background).async {
            do {
                let imagesDirectory = appSupportDirectory.appendingPathComponent(
                    "fw_notes_images", isDirectory: true)
                try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)

                // Determine the file type based on the original file path extension
                let fileExtension = (originalFilePath as NSString).pathExtension.lowercased()

                if fileExtension == "gif" {
                    // Save GIF directly
                    let fileName = UUID().uuidString + ".gif"
                    let fileURL = imagesDirectory.appendingPathComponent(fileName)

                    // Copy the original GIF file
                    try FileManager.default.copyItem(at: URL(fileURLWithPath: originalFilePath), to: fileURL)
                    print("GIF saved at \(fileURL)")
                    
                    DispatchQueue.main.async {
                        imagePaths.append(fileURL.path) // Save the new path
                        saveImagePaths() // Persist paths to a JSON file
                    }
                } else {
                    // Handle other image types (e.g., resizing and saving as PNG)
                    let fileName = UUID().uuidString + ".png"
                    let fileURL = imagesDirectory.appendingPathComponent(fileName)

                    let resizedImage: UIImage
                    if image.size.width > 500 || image.size.height > 500 {
                        let maxDimension: CGFloat = 500
                        let aspectRatio = image.size.width / image.size.height

                        let newSize: CGSize
                        if aspectRatio > 1 {
                            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
                        } else {
                            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
                        }
                        
                        print("newSize: \(newSize)");

                        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                        image.draw(in: CGRect(origin: .zero, size: newSize))
                        resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
                        UIGraphicsEndImageContext()
                    } else {
                        print("No newSize: \(image.size)");
                        resizedImage = image // No resize needed
                    }

                    let imageData = resizedImage.pngData()
                    try imageData?.write(to: fileURL)
                    print("Image saved at \(fileURL)")
                    
                    DispatchQueue.main.async {
                        imagePaths.append(fileURL.path) // Save the new path
                        saveImagePaths() // Persist paths to a JSON file
                    }
                }
            } catch {
                print("Error handling file saveImage: \(error)")
            }
        }
    }


    private func saveImagePaths() {
        let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let uniqueDirectory = appSupportDirectory.appendingPathComponent("fw_notes_images", isDirectory: true)

        // Ensure the directory exists
        if !FileManager.default.fileExists(atPath: uniqueDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: uniqueDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create directory: \(error)")
                return
            }
        }

        let relativePaths = imagePaths.map { URL(fileURLWithPath: $0).lastPathComponent } // Extract relative file names
        let jsonFileURL = uniqueDirectory.appendingPathComponent("imagePaths.json")

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
        let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let uniqueDirectory = appSupportDirectory.appendingPathComponent("fw_notes_images", isDirectory: true)
        let jsonFileURL = uniqueDirectory.appendingPathComponent("imagePaths.json")

        print("Loading image paths from \(jsonFileURL.path)")

        do {
            if FileManager.default.fileExists(atPath: jsonFileURL.path) {
                let data = try Data(contentsOf: jsonFileURL)
                let relativePaths = try JSONDecoder().decode([String].self, from: data)

                // Reconstruct full paths from relative paths
                imagePaths = relativePaths.map { uniqueDirectory.appendingPathComponent($0).path }
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
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var onImagePicked: (UIImage?, String?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController, context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(onImagePicked: onImagePicked)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate,
        UIImagePickerControllerDelegate
    {
        var onImagePicked: (UIImage?, String?) -> Void

        init(onImagePicked: @escaping (UIImage?, String?) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController
                .InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            let url = info[.imageURL] as? URL
            onImagePicked(image, url?.path)  // Pass the image and path
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImagePicked(nil, nil)
            picker.dismiss(animated: true)
        }
    }
}
