import SwiftUI
//
//  MultiFingerGestureView.swift
//  fw_note
//
//  Created by Fung Wing on 27/3/2025.
//
import UIKit

struct MultiFingerGestureView: UIViewRepresentable {

    var onTap: (CGPoint) -> Void
    var onSingleFingerDrag: (CustomDragValue) -> Void
    var onSingleFingerDragEnd: (CustomDragValue) -> Void
    var onMultiFingerGesture: (CustomDragValue) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        // Add pan gesture recognizer
        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:)))
        view.addGestureRecognizer(panGesture)

        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onSingleFingerDrag: onSingleFingerDrag,
            onSingleFingerDragEnd: onSingleFingerDragEnd,
            onMultiFingerGesture: onMultiFingerGesture,
            onTap: onTap
        )
    }

    class Coordinator: NSObject {
        var onSingleFingerDrag: (CustomDragValue) -> Void
        var onSingleFingerDragEnd: (CustomDragValue) -> Void
        var onMultiFingerGesture: (CustomDragValue) -> Void
        var onTap: (CGPoint) -> Void  // Add a new callback for the tap gesture

        private var startLocation: CGPoint = .zero

        init(
            onSingleFingerDrag: @escaping (CustomDragValue) -> Void,
            onSingleFingerDragEnd: @escaping (CustomDragValue) -> Void,
            onMultiFingerGesture: @escaping (CustomDragValue) -> Void,
            onTap: @escaping (CGPoint) -> Void  // Initialize the new callback
        ) {
            self.onSingleFingerDrag = onSingleFingerDrag
            self.onSingleFingerDragEnd = onSingleFingerDragEnd
            self.onMultiFingerGesture = onMultiFingerGesture
            self.onTap = onTap  // Assign the new callback
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended else { return }
            let tapLocation = gesture.location(in: gesture.view)
            print("Tap detected at: \(tapLocation)")
            onTap(tapLocation)  // Pass the location to the callback
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            // Existing pan gesture handling code
            let numberOfTouches = gesture.numberOfTouches
            let location = gesture.location(in: gesture.view)
            let translation = gesture.translation(in: gesture.view)

            let customDragValue = CustomDragValue(
                time: Date(),
                location: location,
                startLocation: startLocation,
                translation: CGSize(
                    width: translation.x, height: translation.y),
                predictedEndTranslation: CGSize.zero,
                predictedEndLocation: location
            )

            if numberOfTouches == 1 {
                switch gesture.state {
                case .began:
                    startLocation = location
                case .changed:
                    onSingleFingerDrag(customDragValue)
                case .ended:
                    onSingleFingerDragEnd(customDragValue)
                    startLocation = .zero
                case .cancelled, .failed:
                    startLocation = .zero
                default:
                    break
                }
            } else if numberOfTouches > 1 {
                if gesture.state == .began || gesture.state == .changed {
                    onMultiFingerGesture(customDragValue)
                }
            } else {
                switch gesture.state {
                case .ended:
                    onSingleFingerDragEnd(customDragValue)
                    startLocation = .zero
                case .cancelled, .failed:
                    startLocation = .zero
                default:
                    break
                }
            }
        }
    }

}
