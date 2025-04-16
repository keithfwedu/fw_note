//
//  PencilDetectionView.swift
//  fw_note
//
//  Created by Fung Wing on 8/4/2025.
//

import SwiftUI
import UIKit

struct PencilDetectionView: UIViewRepresentable {
    var onTap: (TouchData) -> Void
    var onTouchBegin: (TouchData) -> Void
    var onTouchMove: (TouchData) -> Void
    var onTouchEnd: (TouchData) -> Void
    var onTouchCancel: () -> Void

    func makeUIView(context: Context) -> PencilTouchDetectingView {
        let view = PencilTouchDetectingView(
            onTap: onTap,
            onTouchBegin: onTouchBegin,
            onTouchMove: onTouchMove,
            onTouchEnd: onTouchEnd,
            onTouchCancel: onTouchCancel
        )
      
        return view
    }

    func updateUIView(_ uiView: PencilTouchDetectingView, context: Context) {}

    class PencilTouchDetectingView: UIView, UIGestureRecognizerDelegate {

        var onTap: ((TouchData) -> Void)?
        var onTouchBegin: ((TouchData) -> Void)?
        var onTouchMove: ((TouchData) -> Void)?
        var onTouchEnd: ((TouchData) -> Void)?
        var onTouchCancel: (() -> Void)?

        private var startTouchLocation: CGPoint = .zero
        private var isTap: Bool = true

        init(
            onTap: ((TouchData) -> Void)? = nil,
            onTouchBegin: ((TouchData) -> Void)? = nil,
            onTouchMove: ((TouchData) -> Void)? = nil,
            onTouchEnd: ((TouchData) -> Void)? = nil,
            onTouchCancel: (() -> Void)? = nil
        ) {
            super.init(frame: .zero)

            self.onTap = onTap
            self.onTouchBegin = onTouchBegin
            self.onTouchMove = onTouchMove
            self.onTouchEnd = onTouchEnd
            self.onTouchCancel = onTouchCancel
            self.isMultipleTouchEnabled = true
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
            //self.isMultipleTouchEnabled = true
        }

        override func touchesBegan(
            _ touches: Set<UITouch>,
            with event: UIEvent?
        ) {
            print("touches.count \(touches.count)")
            if touches.count > 1 { return }
            guard let touch = touches.first else { return }

            let location = touch.location(in: self)
            startTouchLocation = location

            let touchData = TouchData(
                type: touch.type,
                location: location,
                startLocation: location,
                translation: .zero,
                predictedEndLocation: location,
                predictedEndTranslation: .zero,
                time: Date()
            )
            onTouchBegin?(touchData)  // Optionally handle the tap in touchesBegan
        }

        override func touchesMoved(
            _ touches: Set<UITouch>,
            with event: UIEvent?
        ) {
            if touches.count > 1 { return }
            guard let touch = touches.first else { return }

            let location = touch.location(in: self)
            let translation = CGSize(
                width: location.x - startTouchLocation.x,
                height: location.y - startTouchLocation.y
            )

            let touchData = TouchData(
                type: touch.type,
                location: location,
                startLocation: startTouchLocation,
                translation: translation,
                predictedEndLocation: location,
                predictedEndTranslation: .zero,
                time: Date()
            )
            onTouchMove?(touchData)
        }

        override func touchesEnded(
            _ touches: Set<UITouch>,
            with event: UIEvent?
        ) {
            if touches.count > 1 { return }
            guard let touch = touches.first else { return }

            let location = touch.location(in: self)
            let translation = CGSize(
                width: location.x - startTouchLocation.x,
                height: location.y - startTouchLocation.y
            )

            let touchData = TouchData(
                type: touch.type,
                location: location,
                startLocation: startTouchLocation,
                translation: translation,
                predictedEndLocation: location,
                predictedEndTranslation: .zero,
                time: Date()
            )

            // Detect significant movement, making it not a tap
            isTap =
                !(abs(translation.width) > 10 || abs(translation.height) > 10)

            if isTap {
                onTap?(touchData)
            } else {
                onTouchEnd?(touchData)
            }
        }

        override func touchesCancelled(
            _ touches: Set<UITouch>?,
            with event: UIEvent?
        ) {
            onTouchCancel?()
        }

        override func didMoveToSuperview() {
            super.didMoveToSuperview()

            // Add gesture recognizers for the parent view
            if let superview = self.superview {
                for recognizer in superview.gestureRecognizers ?? [] {
                    recognizer.delegate = self  // Set the delegate to allow simultaneous recognition
                }
            }
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer:
                UIGestureRecognizer
        ) -> Bool {
            return true  // Allow child and parent gestures to work simultaneously
        }
    }
}


