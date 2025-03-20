//
//  PdfNoteView.swift
//  fw_note
//
//  Created by Fung Wing on 19/3/2025.
//

import PDFKit
import SwiftUI
struct CustomColorView: View {
    var body: some View {
        Color.blue
            .frame(width: 200, height: 500) // Define the size of the view
            .cornerRadius(20) // Make the corners rounded
            .shadow(radius: 10) // Add a shadow for styling
    }
}

struct PdfNoteView: View {
    @StateObject private var canvasState = CanvasState()
    @State var noteFile: NoteFile
    @StateObject var navigationState: NavigationState
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0

    var body: some View {

        VStack {
            CanvasToolBar(noteFile: noteFile, canvasState: canvasState)
            VStack {
                if let pdfFilePath = noteFile.pdfFilePath {
                    let absolutePath = FileManager.default.urls(
                        for: .applicationSupportDirectory, in: .userDomainMask
                    )
                    .first!.appendingPathComponent(pdfFilePath).path

                    if let pdfDocument = PDFDocument(
                        url: URL(fileURLWithPath: absolutePath))
                    {
                        TwoFingerZoomableScrollView {
                            LazyVStack(alignment: .center, spacing: 20) {
                                ForEach(0..<pdfDocument.pageCount, id: \.self) {
                                    pageIndex in
                               
                             PDFNotePageView(
                                        canvasState: canvasState,
                                        pageIndex: pageIndex,
                                        notePage: noteFile.notePages[pageIndex],
                                        pdfPage: pdfDocument.page(at: pageIndex),
                                        navigationState: navigationState
                                    )
                                    
                                    .background(
                                        GeometryReader { geometry in
                                            Color.clear
                                                .onAppear {
                                                    calculateVisiblePageArea(geometry: geometry, pageIndex: pageIndex)
                                                }
                                                .onChange(of:geometry.frame(in: .global).minY) { newValue in
                                                    calculateVisiblePageArea(geometry: geometry, pageIndex: pageIndex)
                                                }
                                               
                                        }
                                    )  // Ensure proper height for GeometryReader
                                  
                                }
                            }
                            
                           
                            
                        }
                
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
        }
    }
    
    

        // Calculate visible area of each page and determine the current page
        private func calculateVisiblePageArea(geometry: GeometryProxy, pageIndex: Int) {
            let pageFrame = geometry.frame(in: .global)
            let screenFrame = UIScreen.main.bounds

            let visibleHeight = max(0, min(pageFrame.maxY, screenFrame.maxY) - max(pageFrame.minY, screenFrame.minY))
            let visibleArea = visibleHeight * pageFrame.width
          
            // Update current page if this page has the largest visible area
            if canvasState.currentPageIndex == pageIndex {
                return
            }

            if visibleArea > (UIScreen.main.bounds.height * UIScreen.main.bounds.width) / 2 {
                canvasState.currentPageIndex = pageIndex
              
            }
        }
}
