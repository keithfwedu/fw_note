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
            // Image display area
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 100))], spacing: 10
                ) {
                    ForEach($imagePaths, id: \.self) { path in
                        
                        ZStack {
                            if let uiImage = UIImage(
                                contentsOfFile: path.wrappedValue)
                            {
                                if FileManager.default.fileExists(atPath: path.wrappedValue) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray)
                                        )
                                        .onTapGesture {
                                            // Directly pass the plain String path to addImageToStack
                                            addImageToStack(path: path.wrappedValue)
                                        }
                                } else {
                                    Text("Not Exist")
                                }
                               
                                
                            }
                           
                            Button(action: {
                                removeImage(path.wrappedValue)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .padding(4)
                            }
                            .offset(x: 30, y: -30)
                        }
                    }
                }
            }

            // Add buttons
            HStack {
                Button("Add from Gallery") {
                    selectedSourceType = .photoLibrary
                    isShowingImagePicker = true
                }
                Button("Take Photo") {
                    selectedSourceType = .camera
                    isShowingImagePicker = true
                }
            }
            .padding()
            .buttonStyle(.borderedProminent)

            if isLoading {
                ProgressView("Loading...")
                    .padding()
            }
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(sourceType: selectedSourceType) { image, path in
                if let image = image {
                    saveImage(image)
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

        // Add the file path to the list and save for persistence
        if let filePath = path {
            imagePaths.append(filePath)
            saveImagePaths()
        }

        // Close the image picker if applicable
        // canvasState.showImagePicker = false
    }


    // Save image paths for persistence
    private func saveImage(_ image: UIImage) {
        DispatchQueue.global(qos: .background).async {
            do {
            let imagesDirectory = appSupportDirectory.appendingPathComponent(
                "fw_notes_images", isDirectory: true)
            try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)
            let fileName = UUID().uuidString + ".png" // Save as PNG for compatibility
            let fileURL = imagesDirectory.appendingPathComponent(fileName)

            // Check image dimensions and resize if necessary
            let resizedImage: UIImage
            if image.size.width > 500 || image.size.height > 500 {
                let maxDimension: CGFloat = 500
                let aspectRatio = image.size.width / image.size.height

                // Calculate new size while maintaining aspect ratio
                let newSize: CGSize
                if aspectRatio > 1 {
                    newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
                } else {
                    newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
                }
                
                print("newSize: \(newSize)");

                // Resize image
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
                UIGraphicsEndImageContext()
            } else {
                print("No newSize: \(image.size)");
                resizedImage = image // No resize needed
            }

            // Compress as PNG
            let imageData = resizedImage.pngData()

          
                // Save the image to disk
                try imageData?.write(to: fileURL)
                print("Image saved at \(fileURL)")
                print("Image saved at \(fileURL.path)")
                // Update imagePaths and save paths to disk
                DispatchQueue.main.async {
                    imagePaths.append(fileURL.path) // Save the new path
                    saveImagePaths() // Persist paths to a JSON file
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
