//
//  PDFCanvasView.swift
//  fw_note
//
//  Created by Fung Wing on 20/3/2025.
//

import PDFKit
import SwiftUI

import SwiftUI
import PDFKit

struct PDFCanvasView: UIViewRepresentable {
    let pdfDocument: PDFDocument
    var canvasState: CanvasState
    var noteFile: NoteFile
    @Binding var displayDirection: PDFDisplayDirection // Bindable property to change display direction

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = false
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = displayDirection
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

        // Add page information (Current Page / Total Pages)
        context.coordinator.addPageIndicator(to: pdfView)

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // Update the display direction dynamically
        uiView.displayDirection = displayDirection
        uiView.layoutIfNeeded() // Ensure layout is updated if necessary
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            pdfDocument: pdfDocument, noteFile: noteFile,
            canvasState: canvasState
        )
    }

    class Coordinator: NSObject {
        let pdfDocument: PDFDocument
        private var canvasState: CanvasState
        var noteFile: NoteFile
        var pageIndicatorLabel: UILabel? // Page indicator label to show current/total pages

        init(
            pdfDocument: PDFDocument, noteFile: NoteFile,
            canvasState: CanvasState
        ) {
            self.pdfDocument = pdfDocument
            self.noteFile = noteFile
            self.canvasState = canvasState
        }

        func addCanvasesToPages(pdfView: PDFView) {
            guard let document = pdfView.document else { return }

            // Remove existing custom canvases to avoid duplication
            pdfView.subviews.forEach {
                if $0 is CanvasViewWrapper { $0.removeFromSuperview() }
            }

            guard let scrollView = pdfView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView else { return }

            for pageIndex in 0..<document.pageCount {
                guard let page = document.page(at: pageIndex) else { continue }

                let pageBounds = page.bounds(for: .mediaBox)
                let pageFrame = pdfView.convert(pageBounds, from: page)

                if let renderedSubview = scrollView.subviews.first(where: { $0.frame.contains(pageFrame.origin) }) {
                    let canvasViewWrapper = CanvasViewWrapper(
                        frame: pageFrame,
                        pageIndex: pageIndex,
                        canvasState: canvasState,
                        noteFile: noteFile,
                        notePage: noteFile.notePages[pageIndex]
                    )
                    canvasViewWrapper.backgroundColor = UIColor.clear
                    renderedSubview.addSubview(canvasViewWrapper)
                }
            }
        }

        func addPageIndicator(to pdfView: PDFView) {
            // Remove any existing page indicator first
            pdfView.subviews.filter { $0 is UILabel }.forEach { $0.removeFromSuperview() }

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
                label.leadingAnchor.constraint(equalTo: pdfView.leadingAnchor, constant: 16),
                label.bottomAnchor.constraint(equalTo: pdfView.bottomAnchor, constant: -16),
                label.widthAnchor.constraint(equalToConstant: 120),
                label.heightAnchor.constraint(equalToConstant: 30)
            ])

            self.pageIndicatorLabel = label
            updatePageIndicator(for: pdfView) // Update immediately
        }

        func updatePageIndicator(for pdfView: PDFView) {
            guard let document = pdfView.document, let currentPage = pdfView.currentPage else { return }
            let currentPageIndex = document.index(for: currentPage) + 1 // Page indices are 0-based
            let totalPageCount = document.pageCount
            pageIndicatorLabel?.text = "Page \(currentPageIndex) / \(totalPageCount)"
        }

        @objc func pageDidChange(notification: Notification) {
            guard let pdfView = notification.object as? PDFView else { return }
            updatePageIndicator(for: pdfView)
        }
    }
}
