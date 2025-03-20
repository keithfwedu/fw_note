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
    @StateObject var navigationState: NavigationState


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
                        TwoFingerScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(0..<pdfDocument.pageCount, id: \.self) {
                                    pageIndex in
                                    PDFNotePageView(
                                       
                                        canvasState: canvasState,
                                        pageIndex: pageIndex,
                                        notePage: noteFile.notePages[pageIndex],
                                        pdfPage: pdfDocument.page(at: pageIndex),
                                        navigationState: navigationState
                                    ).clipped()
                                    
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
