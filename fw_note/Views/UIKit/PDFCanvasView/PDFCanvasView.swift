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
    var imageState: ImageState
    var canvasState: CanvasState
    var noteFile: NoteFile
    var noteUndoManager: NoteUndoManager
    var pdfView: CustomPDFView = CustomPDFView()

    @Binding var displayDirection: PDFDisplayDirection  // Bindable property to change display direction

    func makeUIView(context: Context) -> CustomPDFView {

        pdfView.document = pdfDocument
        pdfView.autoScales = false
        pdfView.displayMode = .singlePageContinuous
        pdfView.displaysPageBreaks = true
        pdfView.displayDirection = displayDirection
        pdfView.backgroundColor = UIColor.systemGray4
        pdfView.usePageViewController(false)
        
        pdfView.pageBreakMargins = UIEdgeInsets(
            top: 50,
            left: 0,
            bottom: 50,
            right: 0
        )

        // Access the internal UIScrollView and configure two-finger scrolling
        if let scrollView = pdfView.subviews.first(where: { $0 is UIScrollView }
        ) as? UIScrollView {
            scrollView.delegate = context.coordinator
            scrollView.delaysContentTouches = false
            scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
            scrollView.panGestureRecognizer.maximumNumberOfTouches = 2
        }

        context.coordinator.configure(
            pdfView: pdfView,
            displayDirection: displayDirection
        )  // Pass PDFView to the Coordinator
        setPageBreakMargins(pdfView: pdfView)
        // Add canvases as annotations to each page
        context.coordinator.addCanvasesToPages(
            pdfView: pdfView,
            displayDirection: displayDirection
        )

        // Add page information (Current Page / Total Pages)
        context.coordinator.addPageIndicator(to: pdfView)

        return pdfView
    }

    func updateUIView(_ uiView: CustomPDFView, context: Context) {
        // Update the display direction dynamically
        if uiView.displayDirection != displayDirection {
            uiView.displayDirection = displayDirection
            uiView.scaleFactor = 1.0
            setPageBreakMargins(pdfView: uiView)
            context.coordinator.addCanvasesToPages(
                pdfView: uiView,
                displayDirection: uiView.displayDirection
            )
           
        }

        uiView.layoutDocumentView()
    }

    func setPageBreakMargins(pdfView: CustomPDFView) {
        guard let document = pdfView.document,
            let page = document.page(at: 0)
        else {
            print("no padding")
            return
        }

        let pageBounds = page.bounds(for: .mediaBox)
        let rawPageFrame = pdfView.convert(pageBounds, from: page)
        let screenWidth = UIScreen.main.bounds.width
        let paddingHorizontal = (screenWidth - rawPageFrame.width) / 2

        pdfView.pageBreakMargins =
            displayDirection == .vertical
            ? UIEdgeInsets(
                top: 50,
                left: 0,
                bottom: 50,
                right: 0
            )
            : UIEdgeInsets(
                top: 100,
                left: paddingHorizontal,
                bottom: 100,
                right: paddingHorizontal
            )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            pdfView: pdfView,
            pdfDocument: pdfDocument,
            noteFile: noteFile,
            noteUndoManager: noteUndoManager,
            imageState: imageState,
            canvasState: canvasState

        )
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        weak var pdfView: CustomPDFView?  // Weak reference to avoid retain cycles

        let pdfDocument: PDFDocument
        private var imageState: ImageState
        private var canvasState: CanvasState
        var noteFile: NoteFile
        var noteUndoManager: NoteUndoManager
        var pageIndicatorLabel: UILabel?  // Page indicator label to show current/total pages
        var scaleFactor: CGFloat = 1.0
        var displayDirection: PDFDisplayDirection = .vertical
        var rawPageFrames: [CGRect] = []

        init(
            pdfView: CustomPDFView,
            pdfDocument: PDFDocument,
            noteFile: NoteFile,
            noteUndoManager: NoteUndoManager,
            imageState: ImageState,
            canvasState: CanvasState
        ) {
            self.pdfDocument = pdfDocument
            self.noteFile = noteFile
            self.noteUndoManager = noteUndoManager
            self.imageState = imageState
            self.canvasState = canvasState
            self.pdfView = pdfView

        }

        func configure(
            pdfView: CustomPDFView,
            displayDirection: PDFDisplayDirection
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
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.subviews.first  // Assume first subview is the content
        }

        func togglePageIndicatorLabel(_ show: Bool) {
            UIView.animate(withDuration: 0.3) {
                self.pageIndicatorLabel?.alpha = show ? 1.0 : 0.0
            }
            self.pageIndicatorLabel?.isHidden = !show
        }

        func calculatePageFrameWithMargins(
            pdfView: PDFView,
            page: PDFPage,
            displayDirection: PDFDisplayDirection
        ) -> CGRect {

            // Step 1: Get the page bounds
            let pageBounds = page.bounds(for: .mediaBox)

            // Step 2: Convert to PDFView's coordinate system
            let rawPageFrame = pdfView.convert(pageBounds, from: page)

            // Step 3: Get page margins (if any)
            let pageBreakMargins = pdfView.pageBreakMargins
            let pageIndex = pdfDocument.index(for: page)

            // Step 4: Adjust for margins
            let adjustedFrame = CGRect(
                x: pageIndex == 0
                    ? pageBreakMargins.left
                    : displayDirection == .vertical
                        ? pageBreakMargins.left
                        : rawPageFrame.size.width * CGFloat(pageIndex)
                            + (pageBreakMargins.left * CGFloat(pageIndex) * 2)
                            + pageBreakMargins.left,
                y: pageIndex == 0
                    ? pageBreakMargins.top
                    : displayDirection == .vertical
                        ? rawPageFrame.size.height * CGFloat(pageIndex)
                            + (pageBreakMargins.top * CGFloat(pageIndex) * 2)
                            + pageBreakMargins.top : pageBreakMargins.top,
                width: rawPageFrame.size.width,
                height: rawPageFrame.size.height
            )

            return adjustedFrame
        }

        private func animateZoomAndScroll(pdfView: PDFView, frame: CGRect) {
            // Access the scroll view
            if let scrollView = pdfView.subviews.first(where: {
                $0 is UIScrollView
            }) as? UIScrollView {
                UIView.animate(withDuration: 0.3) {
                    // Zoom to scale factor 1.0
                    pdfView.scaleFactor = 1.0
                }

                // Scroll to center of the tapped page
                let offset = CGPoint(
                    x: frame.minX - pdfView.pageBreakMargins.left,
                    y: frame.minY
                        + (pdfView.displayDirection == .vertical
                            ? pdfView.pageBreakMargins.top
                                + pdfView.pageBreakMargins.bottom
                            : pdfView.pageBreakMargins.top)
                )

                let pdfPoint = scrollView.convert(offset, to: pdfView)

                if let newPage = pdfView.page(for: pdfPoint, nearest: true) {
                    // Adjust content offset based on display direction

                    scrollView.setContentOffset(offset, animated: true)

                    pdfView.go(to: newPage)

                    let currentPageIndex =
                        pdfView.document?.index(for: newPage) ?? 0
                    print("Current page index: \(currentPageIndex)")

                    updatePageIndicator(
                        for: pdfView,
                        currentPageIndex: currentPageIndex
                    )
                }

            }
        }

        func addCanvasesToPages(
            pdfView: CustomPDFView,
            displayDirection: PDFDisplayDirection
        ) {
            guard let document = pdfView.document,
                let documentView = pdfView.documentView
            else { return }

            // Remove existing custom canvases to avoid duplication
            documentView.subviews.forEach {
                if $0 is CanvasViewWrapper { $0.removeFromSuperview() }
            }

            for pageIndex in 0..<document.pageCount {
                guard let page = document.page(at: pageIndex) else { continue }
                guard let documentView = pdfView.documentView else {
                    print("Document view not found")
                    return
                }

                let normalizedPageFrame = calculatePageFrameWithMargins(
                    pdfView: pdfView,
                    page: page,
                    displayDirection: displayDirection
                )

                print(
                    "Adjusted Page Frame for First Page: \(pageIndex) - \(normalizedPageFrame)"
                )

                // pdfView.layoutDocumentView()

                let canvasViewWrapper = CanvasViewWrapper(
                    frame: normalizedPageFrame,
                    pageIndex: pageIndex,
                    pdfView: pdfView,
                    imageState: imageState,
                    canvasState: canvasState,
                    noteFile: noteFile,
                    noteUndoManager: noteUndoManager,
                    notePage: noteFile.notePages[pageIndex],
                    onDoubleTap: {
                        self.animateZoomAndScroll(
                            pdfView: pdfView,
                            frame: normalizedPageFrame
                        )

                    }
                )
                canvasViewWrapper.backgroundColor = UIColor.clear

                canvasViewWrapper.bounds = normalizedPageFrame
                documentView.addSubview(canvasViewWrapper)
                canvasViewWrapper.layer.zPosition = 1
                pdfView.layoutDocumentView()
                //searchText(pdfView: pdfView, searchText: "ap_")
            }
        }

        private func searchText(pdfView: PDFView, searchText: String) {

            guard let document = pdfView.document else { return }

            // Clear previous highlights
            document.cancelFindString()
            pdfView.highlightedSelections = nil

            // Perform search
            let matches = document.findString(
                searchText,
                withOptions: .caseInsensitive
            )
            for match in matches {
                match.color = UIColor.yellow.withAlphaComponent(0.5)  // Highlight color
            }
            pdfView.highlightedSelections = matches
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
                    equalTo: pdfView.leadingAnchor,
                    constant: 16
                ),
                label.bottomAnchor.constraint(
                    equalTo: pdfView.bottomAnchor,
                    constant: -16
                ),
                label.widthAnchor.constraint(equalToConstant: 120),
                label.heightAnchor.constraint(equalToConstant: 30),
            ])

            self.pageIndicatorLabel = label
            updatePageIndicator(for: pdfView, currentPageIndex: nil)  // Update immediately
        }

        func updatePageIndicator(for pdfView: PDFView, currentPageIndex: Int?) {
            guard let document = pdfView.document,
                let currentPage = pdfView.currentPage
            else { return }
            let pageIndex: Int =
                (currentPageIndex != nil)
                ? (currentPageIndex ?? 0) + 1
                : document.index(for: currentPage) + 1  // Page indices are 0-based
            DispatchQueue.main.async {

                self.canvasState.currentPageIndex = document.index(
                    for: currentPage
                )

            }
            let totalPageCount = document.pageCount
            pageIndicatorLabel?.text =
                "Page \(pageIndex) / \(totalPageCount)"

        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let pdfView = pdfView else { return }
            let newScaleFactor = pdfView.scaleFactor
            self.togglePageIndicatorLabel(newScaleFactor > 0.8)
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            guard let pdfView = pdfView else { return }
            let newScaleFactor = pdfView.scaleFactor
            self.togglePageIndicatorLabel(newScaleFactor > 0.8)
            // Convert the visible center point to PDFView's coordinate space
            let visibleCenter = CGPoint(
                x: scrollView.contentOffset.x + scrollView.bounds.width / 2,
                y: scrollView.contentOffset.y + scrollView.bounds.height / 2
            )
            let centerInPDFView = pdfView.convert(
                visibleCenter,
                from: scrollView
            )

            // Find the current page in the PDFView
            if let currentPage = pdfView.page(
                for: centerInPDFView,
                nearest: true
            ) {
                let currentPageIndex =
                    pdfView.document?.index(for: currentPage) ?? 0
                print("Current page index: \(currentPageIndex)")

                updatePageIndicator(
                    for: pdfView,
                    currentPageIndex: currentPageIndex
                )
            }
        }

    }
}
