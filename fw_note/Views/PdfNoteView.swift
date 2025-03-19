//
//  PdfNoteView.swift
//  fw_note
//
//  Created by Fung Wing on 19/3/2025.
//

import PDFKit
import SwiftUI

struct PdfNoteView: View {
    @StateObject private var canvasState = CanvasState()
    @State var noteFile: NoteFile

    var body: some View {

        VStack {
            Text("\(canvasState.currentPageIndex)");
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
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(0..<pdfDocument.pageCount, id: \.self) {
                                    pageIndex in
                                    PDFNotePageView(
                                       
                                        canvasState: canvasState,
                                        pageIndex: pageIndex,
                                        notePage: noteFile.notePages[pageIndex],
                                        pdfPage: pdfDocument.page(at: pageIndex)
                                    ).background(
                                        GeometryReader { geometry in
                                            Color.clear
                                                .onAppear {
                                                    calculateVisiblePageArea(geometry: geometry, pageIndex: pageIndex)
                                                }
                                                .onChange(of: geometry.frame(in: .global).minY) { _, _ in
                                                    calculateVisiblePageArea(geometry: geometry, pageIndex: pageIndex)
                                                }
                                        }
                                    )  // Ensure proper height for GeometryReader
                                }
                            }
                            .padding()
                        }

                        /*ScrollView(.horizontal) { // Horizontal scrolling
                             LazyHStack(spacing: 0) { // LazyHStack for horizontal layout
                             ForEach(0..<pdfDocument.pageCount, id: \.self) { pageIndex in
                             GeometryReader { geometry in
                             PDFViewWrapper(pdfPage: pdfDocument.page(at: pageIndex))
                             .frame(width: geometry.size.width, height: geometry.size.height) // Dynamic width and height
                             }
                             .frame(width: UIScreen.main.bounds.width) // Ensure proper width for GeometryReader
                             }
                             }
                             .padding()
                             }*/

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

struct PDFNotePageView: View {
    var canvasState: CanvasState
    var pageIndex: Int
    var notePage: NotePage
    var pdfPage: PDFPage?
    
    @State private var zoomScale: CGFloat = 1.0 // State variable to track zoom scale
        @State private var lastZoomScale: CGFloat = 1.0 // To track the last gesture value


    var body: some View {
        GeometryReader { geometry in
            ZStack {
                PDFViewWrapper(
                    pdfPage: pdfPage

                )
                .scaleEffect(zoomScale) // Apply zoom
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )  // Dynamic width and height
               
              

             CanvasView(
                    pageIndex: pageIndex,
                    canvasState: canvasState,
                    notePage: notePage

                )
             .allowsHitTesting(canvasState.isCanvasInteractive)
                .scaleEffect(zoomScale) // Apply zoom
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )  // Dynamic width and height
              
               

            }.gesture(
                MagnificationGesture()
                    .onChanged { value in
                        zoomScale = lastZoomScale * value // Update zoom scale dynamically
                    }
                    .onEnded { _ in
                        lastZoomScale = zoomScale // Save the final zoom scale
                    }
            ).frame(
                width: geometry.size.width,
                height: geometry.size.height
            ) // Ensure ZStack matches the GeometryReader
            .clipped()
        }
        .frame(height: pdfPage != nil ? calculatePageHeight(pdfPage: pdfPage!) : UIScreen.main.bounds.height)  // Ensure proper height for GeometryReader
    }
    
    // Calculate page height based on screen width and PDF page aspect ratio
        private func calculatePageHeight(pdfPage: PDFPage) -> CGFloat {
            let pdfBounds = pdfPage.bounds(for: .mediaBox)
            let screenWidth = UIScreen.main.bounds.width - 40 // Account for horizontal padding
            let aspectRatio = pdfBounds.height / pdfBounds.width
            return screenWidth * aspectRatio
        }
}

struct PDFViewWrapper: UIViewRepresentable {
    let pdfPage: PDFPage?

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
       pdfView.autoScales = true  // Automatically scale the content to fit
        pdfView.displayMode = .singlePage  // Show one page at a time
        pdfView.displayDirection = .vertical  // Enable vertical scrolling if needed
        pdfView.translatesAutoresizingMaskIntoConstraints = true  // Allow resizing

        // Assign the page to a new PDFDocument
        if let pdfPage = pdfPage {
            let pdfDocument = PDFDocument()
            pdfDocument.insert(pdfPage, at: 0)  // Insert the page
            pdfView.document = pdfDocument  // Set document
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {

    }
}
