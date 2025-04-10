//
//  CustomPDFView.swift
//  fw_note
//
//  Created by Alex Ng on 29/3/2025.
//

import PDFKit
import SwiftUI

class CustomPDFView: PDFView {

    func disableGestures(for view: UIView, isEnabled: Bool) {
        // Disable gesture recognizers for the current view
        view.gestureRecognizers?.forEach { gesture in
            gesture.isEnabled = isEnabled
        }

        // Recursively call this function for all child subviews
        view.subviews.forEach { subview in
            disableGestures(for: subview, isEnabled: isEnabled)
        }
    }

    func setupGestureHandling() {
        let gestureRecognizer = MultiTouchGestureRecognizer(target: self, action: #selector(handleMultiTouch))
        gestureRecognizer.delegate = gestureRecognizer

        gestureRecognizer.multiTouchHandler = { [weak self] isMultiTouch in
            guard let self = self else { return }

            // Parent-specific action for multi-touch handling
            print("Parent is handling multi-touch: \(isMultiTouch)")

            // Manage subview gestures
          
        }

        self.addGestureRecognizer(gestureRecognizer)
    }

    @objc private func handleMultiTouch(_ gesture: MultiTouchGestureRecognizer) {
        if gesture.state == .began {
            print("CustomPDFView multi-touch gesture began")
            self.documentView?.subviews.forEach { subview in
                if let canvasWrapper = subview as? CanvasViewWrapper {
                    canvasWrapper.disableGestures(true)
                }
            }
        } else if gesture.state == .changed {
            print("CustomPDFView multi-touch gesture changed")
            self.documentView?.subviews.forEach { subview in
                if let canvasWrapper = subview as? CanvasViewWrapper {
                    canvasWrapper.disableGestures(true)
                }
            }
        } else if gesture.state == .ended {
            print("CustomPDFView multi-touch gesture ended")
            self.documentView?.subviews.forEach { subview in
                if let canvasWrapper = subview as? CanvasViewWrapper {
                    canvasWrapper.disableGestures(false)
                }
            }
        }
    }
}
