//
//  PDFCanvasView.swift
//  fw_note
//
//  Created by Fung Wing on 20/3/2025.
//

import SwiftUI
import PDFKit

struct PDFCanvasView: UIViewRepresentable {
    let pdfDocument: PDFDocument
    var canvasState: CanvasState
    var noteFile: NoteFile
   

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .horizontal

        pdfView.usePageViewController(false)
        
    
        // Access the internal UIScrollView and configure two-finger scrolling
        if let scrollView = pdfView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
            scrollView.panGestureRecognizer.maximumNumberOfTouches = 2
        }
        
        // Add observer for page changes
                NotificationCenter.default.addObserver(
                    context.coordinator,
                    selector: #selector(context.coordinator.pageDidChange),
                    name: Notification.Name.PDFViewPageChanged,
                    object: pdfView
                )

        // Add canvases as annotations to each page
        context.coordinator.addCanvasesToPages(pdfView: pdfView)

        return pdfView
    }
    
    


    func updateUIView(_ uiView: PDFView, context: Context) {
        // Ensure updates refresh canvases
       // context.coordinator.addCanvasesToPages(pdfView: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(pdfDocument: pdfDocument, noteFile: noteFile, canvasState: canvasState)
    }

    class Coordinator: NSObject {
        let pdfDocument: PDFDocument
        private var canvasState: CanvasState
        var noteFile: NoteFile
       

        init(pdfDocument: PDFDocument, noteFile: NoteFile, canvasState: CanvasState) {
            self.pdfDocument = pdfDocument
            self.noteFile = noteFile
            self.canvasState = canvasState
            
        }

        func addCanvasesToPages(pdfView: PDFView) {
            guard let document = pdfView.document else { return }

            // Remove existing custom canvases to avoid duplication
            pdfView.subviews.forEach { if $0 is CanvasViewWrapper { $0.removeFromSuperview() } }

            // Access the UIScrollView rendering pages
            guard let scrollView = pdfView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView else { return }

            // Debug: Log all subview frames
            for (index, subview) in scrollView.subviews.enumerated() {
                print("Subview \(index) Frame: \(subview.frame)")
            }

            // Iterate through all pages in the PDFDocument
            for pageIndex in 0..<document.pageCount {
                guard let page = document.page(at: pageIndex) else { continue }

                // Calculate the page bounds in the PDFView's coordinate system
                let pageBounds = page.bounds(for: .mediaBox)
                let pageFrame = pdfView.convert(pageBounds, from: page)

                print("Page \(pageIndex): Calculated Frame in PDFView: \(pageFrame)")

                // Try to find the rendered subview for the current page
                var pageMatchFound = false
                for subview in scrollView.subviews {
                    print("Checking subview for page \(pageIndex): Frame \(subview.frame)")

                    if subview.frame.contains(pageFrame.origin) || subview.frame.intersects(pageFrame) {
                        print("Found rendered subview for page \(pageIndex)")

                        // Create a `CanvasViewWrapper` for this page
                        let canvasViewWrapper = CanvasViewWrapper(
                            frame: pageFrame,
                            pageIndex: pageIndex,
                            canvasState: canvasState,
                            notePage: noteFile.notePages[pageIndex]
                        )
                        canvasViewWrapper.backgroundColor = UIColor.clear // Transparent canvas
                        canvasViewWrapper.layer.borderColor = UIColor.red.cgColor // Debugging border
                        canvasViewWrapper.layer.borderWidth = 1

                        // Attach the canvas to the page view
                        subview.addSubview(canvasViewWrapper)

                        pageMatchFound = true
                        break
                    }
                }

                if !pageMatchFound {
                    print("No matching subview found for page \(pageIndex)")
                }
            }
        }


        /// Synchronize `CustomCanvas` with the corresponding page's size, position, and scale
        private func synchronizeCanvasWithPage(pdfView: PDFView, page: PDFPage, canvas: CanvasViewWrapper, pageView: UIView) {
            // Add a listener for `PDFView` scale and movement changes
         /*  NotificationCenter.default.addObserver(forName: Notification.Name.PDFViewScaleChanged, object: pdfView, queue: .main) { _ in
                self.updateCanvasFrame(pdfView: pdfView, page: page, canvas: canvas, pageView: pageView)
            }
            NotificationCenter.default.addObserver(forName: Notification.Name.PDFViewPageChanged, object: pdfView, queue: .main) { _ in
                self.updateCanvasFrame(pdfView: pdfView, page: page, canvas: canvas, pageView: pageView)
            }*/
        }

        /// Update the `CustomCanvas` frame to match the page's current bounds and position
        private func updateCanvasFrame(pdfView: PDFView, page: PDFPage, canvas: CanvasViewWrapper, pageView: UIView) {
            DispatchQueue.main.async {
                // Ensure the canvas matches the page view's bounds and scale
                canvas.frame = pageView.bounds
                print("Updated canvas frame for page: \(canvas.frame)")
            }
        }

        @objc func pageDidChange(notification: Notification) {
                    guard let pdfView = notification.object as? PDFView,
                          let currentPage = pdfView.currentPage,
                          let document = pdfView.document else { return }

                    // Get the current page index
                    let currentPageIndex = document.index(for: currentPage)
                    print("Page changed to index: \(currentPageIndex)")

                    // Perform additional logic here, such as updating the state
                    canvasState.currentPageIndex = currentPageIndex
                }
    }
}
