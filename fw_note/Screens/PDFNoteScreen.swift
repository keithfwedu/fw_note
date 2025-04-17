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
  
    @State private var pdfDocument: PDFDocument?
    @State private var showSaveConfirmation = false // State for save confirmation dialog
    @State private var isLoading = false // State to track loading
    @State private var searchText = ""
    @Environment(\.presentationMode) var presentationMode // Allows manual dismissal

    init(noteFile: NoteFile) {
        currentProjectId = noteFile.id
        self.noteFile = noteFile

        // Initialize noteUndoManager with noteFile
        self._noteUndoManager = State(
            initialValue: NoteUndoManager(noteFile: noteFile)
        )
        
        let pdfFilePath = FileHelper.getPDFPath(projectId: noteFile.id)
        self._pdfDocument = State(
            initialValue: PDFDocument(url: URL(fileURLWithPath: pdfFilePath))
        )
           
      
    }

    var body: some View {
        ZStack {
            VStack {
                
                CanvasToolBar(
                    pdfDocument: $pdfDocument,
                    noteFile: noteFile,
                    canvasState: canvasState,
                    noteUndoManager: $noteUndoManager
                )
                ZStack {
                  
                    if self.pdfDocument != nil {
                        // Embedding the PDFView
                        PDFCanvasView(
                            pdfDocument: $pdfDocument,
                            imageState: imageState,
                            canvasState: canvasState,
                            noteFile: noteFile,
                            noteUndoManager: $noteUndoManager,
                            searchText: $searchText,
                            displayDirection: $canvasState.displayDirection,
                            onUpdateDocument: { document in
                                print("onUpdate")
                                pdfDocument = document
                            }
                        )
                    } else {
                        VStack {
                            Text("Unable to load PDF")
                                .foregroundColor(.red)
                                .font(.headline)
                        }.frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .navigationTitle(noteFile.title) // Set the navigation title
            .navigationBarTitleDisplayMode(.inline) // Optional: inline style for the title
            .navigationBarBackButtonHidden(true) // Hide the default back button
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // Show the confirmation dialog before saving
                        if(canvasState.isEdited) {
                            showSaveConfirmation = true
                        } else {
                            presentationMode.wrappedValue.dismiss() // Dismiss the view
                        }
                    }) {
                        Image(systemName: "chevron.backward")
                        Text("Back")
                    }
                }
                
                // Search text box in the top-right corner
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    HStack {
                                        TextField("Search", text: $searchText)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .frame(width: 200)
                                       
                                    }
                                }
            }
            .alert("Do you want to save before leaving?", isPresented: $showSaveConfirmation) {
                Button("Save") {
                    Task {
                        isLoading = true // Show loading indicator
                        await savePDF() // Wait for savePDF to complete
                        isLoading = false // Hide loading indicator
                        presentationMode.wrappedValue.dismiss() // Dismiss the view
                    }
                }
                Button("Don't Save") {
                    presentationMode.wrappedValue.dismiss() // Dismiss the view
                }
                Button("Cancel", role: .cancel) { }
            }
        }
        if isLoading {
            // Show a loading view while saving
            LoadingView()
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
       
      
       
        if let pdfDocument = pdfDocument
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
            
            FileHelper.savePDF(projectId: noteFile.id, pdfDocument: pdfDocument)
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
