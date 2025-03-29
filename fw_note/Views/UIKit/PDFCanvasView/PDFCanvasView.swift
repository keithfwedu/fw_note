//
//  PDFCanvasView.swift
//  fw_note
//
//  Created by Fung Wing on 20/3/2025.
//

import PDFKit
import SwiftUI

struct PDFCanvasView: UIViewRepresentable {
    let pdfDocument: PDFDocument
    var canvasState: CanvasState
    var noteFile: NoteFile
    var pdfView: CustomPDFView = CustomPDFView()
    @Binding var displayDirection: PDFDisplayDirection  // Bindable property to change display direction

    func makeUIView(context: Context) -> CustomPDFView {

        pdfView.document = pdfDocument
        pdfView.autoScales = false
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = displayDirection

        pdfView.usePageViewController(false)

        // Access the internal UIScrollView and configure two-finger scrolling
        if let scrollView = pdfView.subviews.first(where: { $0 is UIScrollView }
        ) as? UIScrollView {
            scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
            scrollView.panGestureRecognizer.maximumNumberOfTouches = 2

            scrollView.delaysContentTouches = false
            scrollView.minimumZoomScale = 1
            scrollView.bouncesZoom = false
        }

        // Add observer for page changes
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(context.coordinator.pageDidChange),
            name: Notification.Name.PDFViewPageChanged,
            object: pdfView
        )

        context.coordinator.configure(
            pdfView: pdfView, displayDirection: displayDirection)  // Pass PDFView to the Coordinator

        // Add canvases as annotations to each page
        context.coordinator.addCanvasesToPages(
            pdfView: pdfView)

        // Add page information (Current Page / Total Pages)
        context.coordinator.addPageIndicator(to: pdfView)
        pdfView.setupGestureHandling()
        return pdfView
    }

    func updateUIView(_ uiView: CustomPDFView, context: Context) {
        // Update the display direction dynamically
        if uiView.displayDirection != displayDirection {
            uiView.displayDirection = displayDirection
            uiView.scaleFactor = 1.0

            context.coordinator.addCanvasesToPages(
                pdfView: uiView)

            uiView.layoutDocumentView()

        }

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            pdfView: pdfView,
            pdfDocument: pdfDocument, noteFile: noteFile,
            canvasState: canvasState
        )
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        weak var pdfView: CustomPDFView?  // Weak reference to avoid retain cycles

        let pdfDocument: PDFDocument
        private var canvasState: CanvasState
        var noteFile: NoteFile
        var pageIndicatorLabel: UILabel?  // Page indicator label to show current/total pages
        var scaleFactor: CGFloat = 1.0
        var displayDirection: PDFDisplayDirection = .vertical
        var rawPageFrames: [CGRect] = []

        init(
            pdfView: CustomPDFView,
            pdfDocument: PDFDocument, noteFile: NoteFile,
            canvasState: CanvasState
        ) {
            self.pdfDocument = pdfDocument
            self.noteFile = noteFile
            self.canvasState = canvasState
            self.pdfView = pdfView

        }

        func configure(
            pdfView: CustomPDFView, displayDirection: PDFDisplayDirection
        ) {
            self.pdfView = pdfView
            guard let document = pdfView.document
            else { return }

            for pageIndex in 0..<document.pageCount {
                guard let page = document.page(at: pageIndex) else { continue }
                let pageBounds = page.bounds(for: .mediaBox)
                let pageFrame = pdfView.convert(pageBounds, from: page)
                rawPageFrames.append(pageFrame)
            }
            self.displayDirection = displayDirection
            /* NotificationCenter.default.addObserver(
                self,
                selector: #selector(scaleChanged(_:)),
                name: Notification.Name.PDFViewScaleChanged,
                object: pdfView
            )*/
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.subviews.first  // Assume first subview is the content
        }

        /*@objc func scaleChanged(_ notification: Notification) {
            if let pdfView = notification.object as? PDFView {
                let scaleFactor = pdfView.scaleFactor
                print("Scale factor changed: \(scaleFactor)")
                self.scaleFactor = scaleFactor
                //  addCanvasesToPages(pdfView: pdfView, displayDirection: .vertical, scaleFactor: scaleFactor)
            }
        }*/

        func addCanvasesToPages(
            pdfView: CustomPDFView
        ) {
            guard let document = pdfView.document,
                let documentView = pdfView.documentView
            else { return }

            // Remove existing custom canvases to avoid duplication
            documentView.subviews.forEach {
                if $0 is CanvasViewWrapper { $0.removeFromSuperview() }
            }

            var originOffset: CGPoint = .zero
            if let firstPage = document.page(at: 0) {
                let firstPageBounds = firstPage.bounds(for: .mediaBox)
                originOffset = pdfView.convert(
                    firstPageBounds.origin, to: documentView
                )
            }

            for pageIndex in 0..<document.pageCount {
                guard let page = document.page(at: pageIndex) else { continue }
                let pageBounds = page.bounds(for: .mediaBox)
                let rawPageFrame = pdfView.convert(pageBounds, from: page)

                let normalizedPageFrame = CGRect(
                    x: rawPageFrame.origin.x + originOffset.x,
                    y: rawPageFrame.origin.y + originOffset.y,
                    width: rawPageFrames[pageIndex].width,
                    height: rawPageFrames[pageIndex].height
                )
                pdfView.layoutDocumentView()

                print(
                    "pageFrame \(rawPageFrame.midX), \(rawPageFrame.midY) - \(rawPageFrame) - \(documentView.subviews[pageIndex].frame) - \(normalizedPageFrame) - \(document.pageCount) - \( documentView.subviews.count) - \(pageIndex) - \(documentView.subviews)"
                )

               
                let canvasViewWrapper = CanvasViewWrapper(
                    frame: normalizedPageFrame,
                    pageIndex: pageIndex,
                    pdfView: pdfView,
                    canvasState: canvasState,
                    noteFile: noteFile,
                    notePage: noteFile.notePages[pageIndex]
                )

                canvasViewWrapper.backgroundColor = UIColor.clear
                documentView.addSubview(canvasViewWrapper)

                // documentView.addSubview(canvasViewWrapper)
                canvasViewWrapper.layer.zPosition = 1

            }
        }

        func addPageIndicator(to pdfView: PDFView) {
            // Remove any existing page indicator first
            pdfView.subviews.filter { $0 is UILabel }.forEach {
                $0.removeFromSuperview()
            }

            let label = UILabel()
            label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            label.textColor = UIColor.white
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 14)
            label.layer.cornerRadius = 8
            label.clipsToBounds = true
            label.translatesAutoresizingMaskIntoConstraints = false
            pdfView.addSubview(label)

            // Position label at the bottom-left corner
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(
                    equalTo: pdfView.leadingAnchor, constant: 16),
                label.bottomAnchor.constraint(
                    equalTo: pdfView.bottomAnchor, constant: -16),
                label.widthAnchor.constraint(equalToConstant: 120),
                label.heightAnchor.constraint(equalToConstant: 30),
            ])

            self.pageIndicatorLabel = label
            updatePageIndicator(for: pdfView)  // Update immediately
        }

        func updatePageIndicator(for pdfView: PDFView) {
            guard let document = pdfView.document,
                let currentPage = pdfView.currentPage
            else { return }
            let currentPageIndex = document.index(for: currentPage) + 1  // Page indices are 0-based
            canvasState.currentPageIndex = document.index(for: currentPage)
            let totalPageCount = document.pageCount
            pageIndicatorLabel?.text =
                "Page \(currentPageIndex) / \(totalPageCount)"
        }

        @objc func pageDidChange(notification: Notification) {
            guard let pdfView = notification.object as? PDFView else { return }
            updatePageIndicator(for: pdfView)
        }

    }
}
