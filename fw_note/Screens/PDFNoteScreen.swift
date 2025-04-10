//
//  PDFNoteScreen.swift
//  fw_note
//
//  Created by Fung Wing on 20/3/2025.
//

import PDFKit
import SwiftUI

struct PdfNoteScreen: View {
    @StateObject private var canvasState = CanvasState()
    @StateObject private var imageState = ImageState()
    @State var noteFile: NoteFile
    @State var noteUndoManager: NoteUndoManager

    init(noteFile: NoteFile) {
        self.noteFile = noteFile
        // Initialize noteUndoManager with noteFile
        self._noteUndoManager = State(initialValue: NoteUndoManager(noteFile: noteFile))
    }

    var body: some View {
        VStack {
            CanvasToolBar(noteFile: noteFile, canvasState: canvasState, noteUndoManager: noteUndoManager)
            ZStack {
                let pdfFilePath = FileHelper.getPDFPath(projectId: noteFile.id)
                if let pdfDocument = PDFDocument(url: URL(fileURLWithPath: pdfFilePath)) {
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
                    noteUndoManager: noteUndoManager,
                    noteFile: noteFile
                )
            }
        }
        .background(Color(UIColor.systemGray6))
        .navigationTitle(noteFile.title) // Set the navigation title
        .navigationBarTitleDisplayMode(.inline) // Optional: inline style for the title
        .navigationBarBackButtonHidden(false) // Ensure the default back button is visible
    }
}
