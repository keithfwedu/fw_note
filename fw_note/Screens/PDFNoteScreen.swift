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
                                noteFile: noteFile
                            )
                            
                            
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
                    
                    if canvasState.selectionModeIndex == 3 {
                        LaserCanvasView()
                            .allowsHitTesting(true)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                    }

                    
                }
            }
       
    }

}

