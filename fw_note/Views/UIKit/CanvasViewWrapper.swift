//
//  CanvasViewWrapper.swift
//  fw_note
//
//  Created by Alex Ng on 20/3/2025.
//
import UIKit
import SwiftUI


class GestureState: ObservableObject {
    @Published var areGesturesEnabled: Bool = true  // Default to enabled
}


class CanvasViewWrapper: UIView, UIGestureRecognizerDelegate {
    var pageIndex: Int
    private var hostingController: UIHostingController<CanvasView>?
    var gestureState = GestureState()
  
    var pdfView: CustomPDFView
    
    func disableGestures(_ isDisabled: Bool) {
            gestureState.areGesturesEnabled = !isDisabled  // Toggle gesture state dynamically
        }

    init(frame: CGRect, pageIndex: Int, pdfView: CustomPDFView, canvasState: CanvasState, noteFile: NoteFile, notePage: NotePage) {
        self.pageIndex = pageIndex
       
        self.pdfView = pdfView
        super.init(frame: frame)

        let canvasView = CanvasView(
            pageIndex: pageIndex,
            onGesture: { scale, translation in
                self.handleGesture(scale: scale, translation: translation)
            },
            gestureState: gestureState,
            canvasState: canvasState,
            noteFile: noteFile,
            notePage: notePage
        )

        hostingController = UIHostingController(rootView: canvasView)
        if let hostingView = hostingController?.view {
            hostingView.frame = self.bounds
            hostingView.backgroundColor = .clear
            hostingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.addSubview(hostingView)
        }

      
    }
    
    private func handleGesture(scale: CGFloat, translation: CGSize) {
            // Post gesture updates to PDFCanvasView
            NotificationCenter.default.post(
                name: Notification.Name("CanvasGesture"),
                object: ["scale": scale, "translation": translation]
            )
        }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        hostingController?.view.frame = self.bounds
    }

    // Delegate to allow simultaneous two-finger gestures for zooming
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            // Allow only one-finger gestures
            return panGesture.numberOfTouches == 1
        }
        return false
    }
}
