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

    var body: some View {

        VStack {
            CanvasToolBar(noteFile: noteFile, canvasState: canvasState)
            ZStack {
               let pdfFilePath = FileHelper.getPDFPath(projectId: noteFile.id)
                    if let pdfDocument = PDFDocument(
                        url: URL(fileURLWithPath: pdfFilePath ))
                    {
                        // Embedding the PDFView
                        PDFCanvasView(
                            pdfDocument: pdfDocument,
                            imageState: imageState,
                            canvasState: canvasState,
                            noteFile: noteFile,
                            displayDirection: $canvasState.displayDirection
                        )

                        /* */

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
                    noteFile: noteFile)

            }

        }
        
        .background(Color(UIColor.systemGray6))
        .navigationTitle(noteFile.title)  // Set the navigation title
        .navigationBarTitleDisplayMode(.inline)  // Optional: inline style for the title
        .navigationBarBackButtonHidden(false)  // Ensure the default back button is visible

    }
}
