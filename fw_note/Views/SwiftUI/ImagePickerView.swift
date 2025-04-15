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
    @ObservedObject var noteUndoManager: NoteUndoManager

    @State private var images: [UIImage] = []
    @State private var isShowingImagePicker = false
    @State private var isShowFilePicker = false
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
                            isShowFilePicker = false
                        }
                        Divider()
                        Button("Take Photo") {
                            selectedSourceType = .camera
                            isShowingPopover = false
                            isShowingImagePicker = true
                            isShowFilePicker = false
                        }
                        Divider()
                        Button("Add from File") {
                            isShowingPopover = false
                            isShowingImagePicker = false
                            isShowFilePicker = true
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
                                    if image.isGIF {
                                        GIFView(
                                            path: image.absolutePath,
                                            targetSize: CGSize(
                                                width: 100, height: 100)
                                        )
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    Color.gray, lineWidth: 1)
                                        )
                                        .onTapGesture {
                                            addImageToStack(image: image)
                                        }
                                    } else {
                                        if let uiImage = UIImage(
                                            contentsOfFile: image.absolutePath)
                                        {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .frame(width: 100, height: 100)
                                                .scaledToFit()
                                                .cornerRadius(10)
                                                .overlay(
                                                    RoundedRectangle(
                                                        cornerRadius: 10
                                                    )
                                                    .stroke(
                                                        Color.gray, lineWidth: 1
                                                    )
                                                )
                                                .onTapGesture {
                                                    addImageToStack(
                                                        image: image)
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
        .sheet(isPresented: $isShowingImagePicker) {
            MediaPicker(
                mediaType: selectedSourceType,
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
        .fileImporter(
            isPresented: $isShowFilePicker,
            allowedContentTypes: [.image, .gif],
            allowsMultipleSelection: false
        ) { result in
            print(result);
        }
        .onAppear {
            imageState.loadImages()
        }

    }

    private func addImageToStack(image: OriginalImageObj) {
        print("image.path \(image.path)")
        let projectImagePath = FileHelper.copyImageToProject(imagePath: image.path, projectId: noteFile.id)
      
        // Calculate base position
        let pageIndex = canvasState.currentPageIndex
        let page = noteFile.notePages[pageIndex]

        let basePosition = page.pageCenterPoint
        let newPosition = CGPoint(x: basePosition.x, y: basePosition.y)

        // Create the ImageObj with the filtered and adjusted position
        let newImageObj = ImageObj(
            path: projectImagePath,
            position: newPosition,
            size: image.size
        )

        print(newImageObj)

        // Create a new CanvasObj containing the ImageObj
        let newCanvasObj = CanvasObj(lineObj: nil, imageObj: newImageObj)

        // Add the new CanvasObj to the canvas stack
        page.canvasStack.append(
            newCanvasObj)

        canvasState.canvasMode = CanvasMode.draw
        // Add the operation to the undo stack
        noteUndoManager.addToUndo(
            pageIndex: pageIndex,
            canvasStack: page.canvasStack
        )
    }

}
