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
                    addImageToStack(path: path)
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

        // Add the new image object to the image stack
        noteFile.notePages[canvasState.currentPageIndex].imageStack.append(
            newImageObj)

        // Add the operation to the undo stack
        noteFile.addToUndo(
            pageIndex: canvasState.currentPageIndex,
            lineStack: noteFile.notePages[canvasState.currentPageIndex]
                .lineStack,
            imageStack: noteFile.notePages[canvasState.currentPageIndex]
                .imageStack
        )

        // Add the file path to the list and save for persistence
        if path != nil {
            imagePaths.append(path ?? "")
            saveImagePaths()
        }

        canvasState.showImagePicker = false

    }

    // Save image paths for persistence
    private func saveImage(_ image: UIImage) {
        DispatchQueue.global(qos: .background).async {
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! // Updated for long-term storage
            let fileName = UUID().uuidString + ".png" // Save as PNG for compatibility
            let fileURL = directory.appendingPathComponent(fileName)

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

                // Resize image
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
                UIGraphicsEndImageContext()
            } else {
                resizedImage = image // No resize needed
            }

            // Compress as PNG
            let imageData = resizedImage.pngData()

            do {
                // Save the image to disk
                try imageData?.write(to: fileURL)
                print("Image saved at \(fileURL)")

                // Update imagePaths and save paths to disk
                DispatchQueue.main.async {
                    imagePaths.append(fileURL.path) // Save the new path
                    saveImagePaths() // Persist paths to a JSON file
                }
            } catch {
                print("Failed to save image: \(error)")
            }
        }
    }

    private func saveImagePaths() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! // Path for storing paths
        let fileURL = directory.appendingPathComponent("imagePaths.json") // JSON file name

        do {
            let data = try JSONEncoder().encode(imagePaths) // Encode paths into JSON
            try data.write(to: fileURL) // Write the JSON to disk
            print("Image paths saved at \(fileURL)")
        } catch {
            print("Failed to save image paths: \(error)")
        }
    }

    // Load saved image paths
    private func loadSavedImagePaths() {
        let directory = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        ).first!
        let fileURL = directory.appendingPathComponent("imagePaths.json")

        do {
            let data = try Data(contentsOf: fileURL)
            imagePaths = try JSONDecoder().decode([String].self, from: data)
            print("Loaded image paths: \(imagePaths)")
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
