//
//  PDFNotePageView.swift
//  fw_note
//
//  Created by Fung Wing on 20/3/2025.
//

import PDFKit
import SwiftUI

struct PDFNotePageView: View {
    @StateObject var canvasState: CanvasState
    var pageIndex: Int
    var notePage: NotePage
    var pdfPage: PDFPage?
    @StateObject var navigationState: NavigationState

    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var pdfFrame: CGRect = .zero

    var body: some View {

        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // PDFViewWrapper: Pass frame and scale updates
                PDFViewWrapper(
                    pdfPage: pdfPage,
                    isNavigationVisible: navigationState.isNavigationVisible,
                    onFrameChange: { frame, pdfScale in
                        DispatchQueue.main.async {
                            self.pdfFrame = frame
                        }

                    }
                )
                .allowsHitTesting(shouldAllowHitTesting)  // Disable interaction when drawing
                .scaleEffect(zoomScale)  // Apply overall zoom
                .frame(
                    width: geometry.size.width,
                    height: calculatePageHeight(for: geometry.size.width)
                )
                .clipped()

                // CanvasView: Synchronize width, height, and scale
                CanvasView(
                    pageIndex: pageIndex,
                    canvasState: canvasState,
                    notePage: notePage
                )
                .allowsHitTesting(shouldAllowHitTesting)
                .scaleEffect(zoomScale)  // Combine zoom and PDFView scaling
                .frame(
                    width: pdfFrame.width,
                    height: pdfFrame.height  // Match PDF size dynamically
                )
                .clipped()

                if canvasState.selectionModeIndex == 3 {
                    LaserCanvasView()
                        .allowsHitTesting(true)
                        .scaleEffect(zoomScale)
                        .frame(
                            width: pdfFrame.width,
                            height: pdfFrame.height  // Match PDF size dynamically
                        )
                        .clipped()
                }

            }
            /*.gesture(
                MagnificationGesture()
                    .onChanged { value in
                        zoomScale = lastZoomScale * value  // Dynamically adjust zoom scale
                    }
                    .onEnded { _ in
                        lastZoomScale = zoomScale  // Save the zoom scale
                    }
            )*/
            .clipped()
        }
        .frame(
            height: pdfFrame.height > 0
                ? pdfFrame.height : UIScreen.main.bounds.height  // Use PDF height dynamically
        )

    }

    private var shouldAllowHitTesting: Bool {
        return !(canvasState.selectionModeIndex == 3)
            && canvasState.isCanvasInteractive
    }

    // Dynamically calculate the height of the PDF based on its width and aspect ratio
    private func calculatePageHeight(for width: CGFloat) -> CGFloat {
        guard let pdfPage = pdfPage else { return 0 }
        let pdfBounds = pdfPage.bounds(for: .mediaBox)  // Get PDF dimensions
        let aspectRatio = pdfBounds.height / pdfBounds.width
        return width * aspectRatio
    }
}
