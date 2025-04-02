//
//  ImagePickerView.swift
//  fw_note
//
//  Created by Fung Wing on 25/3/2025.
//

import Photos
import SwiftUI

struct ImagePickerView: View {
    @ObservedObject var noteFile: NoteFile
    @ObservedObject var imageState: ImageState
    @ObservedObject var canvasState: CanvasState
    
    @State private var images: [UIImage] = []
    @State private var isShowingImagePicker = false
    @State private var isShowingPopover = false
    @State private var selectedSourceType: UIImagePickerController.SourceType =
        .photoLibrary
    @State private var isLoading = false
    
   
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
                        ForEach(imageState.images) { image in
                            ZStack {
                                if FileManager.default.fileExists(
                                    atPath: image.absolutePath)
                                {
                                    if(image.isGIF) {
                                        GIFView(
                                            path: image.absolutePath,
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
                                            addImageToStack(image: image)
                                        }
                                    }else {
                                        if let uiImage = UIImage(contentsOfFile: image.absolutePath) {
                                             Image(uiImage: uiImage)
                                                .resizable()
                                                .frame(width: 100, height: 100)
                                                .scaledToFit()
                                                .cornerRadius(10)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color.gray, lineWidth: 1)
                                                )
                                                .onTapGesture {
                                                    addImageToStack(image: image)
                                                }
                                                } else {
                                                    Text("Image could not be loaded.")
                                                        .foregroundColor(.red)
                                                }
                                      
                                           
                                    }
                                } else {
                                    Text("File Missing")
                                        .foregroundColor(.red)
                                        .frame(width: 100, height: 100)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(10)
                                }

                                Button(action: {
                                    imageState.removeImage(image)
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
            MediaPicker(
                mediaType: .photoLibrary,
                onMediaSelected: { data, isGIF in
                    // process your data

                    ImageHelper.checkPhotoLibraryPermission { granted in
                        if granted {
                            print("Photo Library access granted!")
                            imageState.saveImageFromData(data, isGif: isGIF)
                        } else {
                            print("Photo Library access denied.")
                            // Handle denied access gracefully, e.g., show an alert
                        }
                    }

                },
                onCancel: {
                    self.isShowingImagePicker = false
                }
            )

        }
        .onAppear {
            imageState.loadImages()
        }

    }

    private func addImageToStack(image: OriginalImageObj) {
        // Calculate base position
        let pageIndex = canvasState.currentPageIndex
        let page = noteFile.notePages[pageIndex]

        let basePosition = page.pageCenterPoint
        let newPosition = CGPoint(x: basePosition.x, y: basePosition.y)

        // Create the ImageObj with the filtered and adjusted position
        let newImageObj = ImageObj(
            id: UUID(),
            path: image.absolutePath,
            position: newPosition,
            size: image.size
        )
        
        print(newImageObj);

        // Create a new CanvasObj containing the ImageObj
        let newCanvasObj = CanvasObj(lineObj: nil, imageObj: newImageObj)

        // Add the new CanvasObj to the canvas stack
        page.canvasStack.append(
            newCanvasObj)

        // Add the operation to the undo stack
        noteFile.addToUndo(
            pageIndex: pageIndex,
            canvasStack: page.canvasStack
        )
    }


    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            print("Checking provider...")

            // Check if the provider has an item conforming to "public.image"
            if provider.hasItemConformingToTypeIdentifier("public.image") {
                canvasState.isDragging = true

                if provider.registeredTypeIdentifiers.contains(
                    "com.compuserve.gif")
                {
                    print("Detected GIF")

                    // Load the GIF using its type identifier
                    provider.loadItem(
                        forTypeIdentifier: "com.compuserve.gif", options: nil
                    ) { item, error in
                        if let data = item as? Data {
                            // Successfully loaded the GIF data
                            print(
                                "Successfully loaded GIF data: \(data.count) bytes"
                            )

                        } else if let url = item as? URL {
                            print("GIF URL received: \(url)")
                            self.saveTemporaryGIF(from: url)
                        } else {
                            print(
                                "Failed to load GIF: \(String(describing: error))"
                            )
                        }
                    }

                } else {
                    // Handle non-GIF image formats
                    provider.loadObject(ofClass: UIImage.self) { item, error in
                        guard error == nil, let uiImage = item as? UIImage
                        else {
                            print(
                                "Failed to load image: \(String(describing: error))"
                            )
                            return
                        }

                        do {
                            let imagesDirectory =
                                appSupportDirectory.appendingPathComponent(
                                    "fw_notes_images", isDirectory: true
                                )

                            try FileManager.default.createDirectory(
                                at: imagesDirectory,
                                withIntermediateDirectories: true,
                                attributes: nil
                            )

                            let fileName = UUID().uuidString + ".png"
                            let fileURL =
                                imagesDirectory.appendingPathComponent(fileName)

                            let resizedImage = ImageHelper.resizeImage(uiImage)
                            let imageData = resizedImage.pngData()
                            try imageData?.write(to: fileURL)

                            print("PNG saved successfully at \(fileURL)")
                            DispatchQueue.global(qos: .background).async {
                                isLoading = true
                                // Determine the file type based on the original file path extension
                                DispatchQueue.main.async {
                                    imageState.saveImage(filePath: fileURL.path)
                                    isLoading = false
                                }

                            }
                    
                        } catch {
                            print(
                                "Error saving image: \(error.localizedDescription)"
                            )
                        }
                    }
                }
            }
            return true  // Successfully handled provider
        }

        return false  // No valid providers were processed
    }

    func saveTemporaryGIF(from tempURL: URL) {
        do {
            let documentsDirectory = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first!
            let fileName = UUID().uuidString + ".gif"
            let destinationURL = documentsDirectory.appendingPathComponent(
                fileName)
            print("1. GIF successfully saved at \(destinationURL)")
            // Copy file to a safe location
            if FileManager.default.fileExists(atPath: tempURL.path) {
                print("File exists at \(tempURL.path)")
            } else {
                print("File does not exist at \(tempURL.path)")
            }
            try FileManager.default.copyItem(at: tempURL, to: destinationURL)
            print("GIF successfully saved at \(destinationURL)")
        } catch {
            print("Error saving GIF: \(error.localizedDescription)")
        }
    }
    
    
       
    
}
