//
//  PDFNoteScreen.swift
//  fw_note
//
//  Created by Fung Wing on 20/3/2025.
//

import PDFKit
import SwiftUI

struct PdfNoteScreen: View {
    @StateObject var canvasState = CanvasState()
    @StateObject var imageState = ImageState()
    @State var noteFile: NoteFile
    @State var noteUndoManager: NoteUndoManager
    @Environment(\.presentationMode) var presentationMode  // Allows manual dismissal

    init(noteFile: NoteFile) {
        currentProjectId = noteFile.id
        self.noteFile = noteFile

        // Initialize noteUndoManager with noteFile
        self._noteUndoManager = State(
            initialValue: NoteUndoManager(noteFile: noteFile)
        )
    }

    var body: some View {
        VStack {
            CanvasToolBar(
                noteFile: noteFile,
                canvasState: canvasState,
                noteUndoManager: noteUndoManager
            )
            ZStack {
                let pdfFilePath = FileHelper.getPDFPath(projectId: noteFile.id)
                if let pdfDocument = PDFDocument(
                    url: URL(fileURLWithPath: pdfFilePath)
                ) {
                    // Embedding the PDFView
                    PDFCanvasView(
                        pdfDocument: pdfDocument,
                        imageState: imageState,
                        canvasState: canvasState,
                        noteFile: noteFile,
                        noteUndoManager: noteUndoManager,
                        displayDirection: $canvasState.displayDirection
                    )
                } else {
                    Text("Unable to load PDF")
                        .foregroundColor(.red)
                        .font(.headline)
                }

                ImageSideMenu(
                    width: 280,
                    isOpen: canvasState.showImagePicker,
                    menuClose: {
                        canvasState.showImagePicker = false
                    },
                    imageState: imageState,
                    canvasState: canvasState,
                    noteUndoManager: noteUndoManager,
                    noteFile: noteFile
                )
            }
        }
        .background(Color(UIColor.systemGray6))
        .navigationTitle(noteFile.title)  // Set the navigation title
        .navigationBarTitleDisplayMode(.inline)  // Optional: inline style for the title
        .navigationBarBackButtonHidden(false)  // Ensure the default back button is visible
        .navigationBarBackButtonHidden(true)  // Hide default back button
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    Task {
                        await savePDF()  // Wait for savePDF to complete

                    }
                }) {
                    Image(systemName: "chevron.backward")
                    Text("Back")
                }
            }
        }
    }

    // Mock functions
    func savePDF() async {
        print("Save PDF")
        FileHelper.saveProject(noteFile: noteFile)
        // print("draw2 \(canvasState.canvasPool[0])")
        let pageSize = CGSize(
            width: noteFile.notePages[0].canvasWidth,
            height: noteFile.notePages[0].canvasHeight
        )
        let canvasSnapshot = canvasState.canvasPool[0].frame(
            width: pageSize.width,
            height: pageSize.height
        ).snapshot()
       
      
        let pdfFilePath = FileHelper.getPDFPath(projectId: noteFile.id)
        if let pdfDocument = PDFDocument(url: URL(fileURLWithPath: pdfFilePath))
        {
            guard
                let page = pdfDocument.page(
                    at: canvasState.currentPageIndex
                )
            else {
                print(
                    "Error: Could not get page at index \(canvasState.currentPageIndex)"
                )
                return
            }

            let pdfImage = page.thumbnail(of: pageSize, for: .mediaBox)

            guard
                let combinedImage = combineImages(
                    baseImage: pdfImage,
                    overlayImage: canvasSnapshot
                )
            else {
                print("Error combining images")
                return
            }

            let currentUserId = FileHelper.getCurrentUserId()  // Fetch the current user ID
            let baseDirectory = FileHelper.getBaseDirectory()  // Base directory of your app

            // Define the project and images directories
            let projectDirectory = baseDirectory.appendingPathComponent(
                "users/\(currentUserId)/projects/\(noteFile.id.uuidString)",
                isDirectory: true
            )
            let thumbnailPath = projectDirectory.appendingPathComponent(
                "thumbnail.jpg"
            )
            do {
                try combinedImage.pngData()?.write(to: thumbnailPath)
            } catch {
                print(error)
            }

            presentationMode.wrappedValue.dismiss()  // Dismiss the view programmatically
        }

    }

    func combineImages(
        baseImage: UIImage,
        overlayImage: UIImage
    ) -> UIImage? {
        let size = baseImage.size  // Use the size of the base image
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)

        // Draw the base image
        baseImage.draw(in: CGRect(origin: .zero, size: size))

        // Draw the overlay image on top
        overlayImage.draw(in: CGRect(origin: .zero, size: size))
        
        // Generate the combined image
        let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return combinedImage
    }
}
