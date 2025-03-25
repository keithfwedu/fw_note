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
    @State var noteFile: NoteFile

    var body: some View {

        VStack {

            CanvasToolBar(noteFile: noteFile, canvasState: canvasState)
            ZStack {
                if let pdfFilePath = noteFile.pdfFilePath {
                    let absolutePath = FileManager.default.urls(
                        for: .applicationSupportDirectory, in: .userDomainMask
                    )
                    .first!.appendingPathComponent(pdfFilePath).path

                    if let pdfDocument = PDFDocument(
                        url: URL(fileURLWithPath: absolutePath))
                    {
                        // Embedding the PDFView

                        PDFCanvasView(
                            pdfDocument: pdfDocument,
                            canvasState: canvasState,
                            noteFile: noteFile,
                            displayDirection: $canvasState.displayDirection
                        ).frame(maxWidth: .infinity, maxHeight: .infinity)  // Ensure it occupies space

                        // Sliding view
                        VStack {
                            ImagePickerView(
                                noteFile: noteFile, canvasState: canvasState
                            )
                        }
                        .frame(maxWidth: 300, maxHeight: .infinity)
                        .background(Color.gray)
                        .edgesIgnoringSafeArea(.vertical)  // Ensure it fills top and bottom
                        .offset(
                            x: canvasState.showImagePicker
                                ? (UIScreen.main.bounds.width / 2) - 150
                                : (UIScreen.main.bounds.width / 2) + 150
                        )  // Animate horizontally
                        .animation(
                            .easeInOut(duration: 0.3),
                            value: canvasState.showImagePicker)  // Smooth animation

                    } else {
                        Text("Unable to load PDF")
                            .foregroundColor(.red)
                            .font(.headline)
                    }
                } else {
                    Text("PDF path not available")
                        .foregroundColor(.red)
                        .font(.headline)
                }

            }
        }.navigationTitle(noteFile.title)  // Set the navigation title
            .navigationBarTitleDisplayMode(.inline)  // Optional: inline style for the title
            .navigationBarBackButtonHidden(false)  // Ensure the default back button is visible

    }

}
