//
//  PDFViewWrapper.swift
//  fw_note
//
//  Created by Fung Wing on 20/3/2025.
//

import PDFKit
import SwiftUI

struct PDFViewWrapper: UIViewRepresentable {
    let pdfPage: PDFPage?
    let isNavigationVisible: Bool // Pass visibility state
    let onFrameChange: (CGRect, CGFloat) -> Void // Callback for frame and scale updates

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = false
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        if let pdfPage = pdfPage {
            let pdfDocument = PDFDocument()
            pdfDocument.insert(pdfPage, at: 0)
            pdfView.document = pdfDocument
            if pdfView.currentPage != nil {
                let pdfScale = calculateScale(for: pdfView);
               
               pdfView.scaleFactor = pdfScale ?? 0.0
               
                // Update frame and scale after rendering
                DispatchQueue.main.async {
                    updateFrameAndScale(pdfView: pdfView)
                }
            }
        }

        return pdfView
    }
    

    
    func calculateScale(for pdfView: PDFView) -> CGFloat? {
        guard let page = pdfView.currentPage else { return nil }
         
        let pageBounds = page.bounds(for: .cropBox) // Use cropBox for the page's actual content size
        let pdfPageWidth = pageBounds.width
       
        // Calculate the scale factor to fit the page width to the container width
        let scaleFactor = UIScreen.main.bounds.width / pdfPageWidth
        
        print(scaleFactor);
        return scaleFactor
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        
    }

    private func updateFrameAndScale(pdfView: PDFView) {
        if let page = pdfView.currentPage {
            let pageBounds = page.bounds(for: .cropBox)
            let pdfScale = pdfView.scaleFactor
            let scaledWidth = pageBounds.width * pdfScale
            let scaledHeight = pageBounds.height * pdfScale
            let frame = CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
            print("frame");
            print(frame);
            print(pdfScale);
            // Notify frame and scale changes
            onFrameChange(frame, pdfScale)
        }
    }
}

