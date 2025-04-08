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
    var onTouchMove: (TouchData) -> Void
    var onTouchEnd: (TouchData) -> Void

    func makeUIView(context: Context) -> PencilTouchDetectingView {
        let view = PencilTouchDetectingView()
        view.onTap = onTap
        view.onTouchMove = onTouchMove
        view.onTouchEnd = onTouchEnd
        return view
    }

    func updateUIView(_ uiView: PencilTouchDetectingView, context: Context) {}

    class PencilTouchDetectingView: UIView {
        var onTap: ((TouchData) -> Void)?
        var onTouchMove: ((TouchData) -> Void)?
        var onTouchEnd: ((TouchData) -> Void)?

        private var startTouchLocation: CGPoint = .zero
        private var isTap: Bool = true

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            startTouchLocation = location
            isTap = true // Assume it's a tap until movement is detected

            let touchData = TouchData(
                type: touch.type,
                location: location,
                startLocation: location,
                translation: .zero,
                predictedEndLocation: location,
                predictedEndTranslation: .zero,
                time: Date()
            )
            onTap?(touchData) // Optionally handle the tap in touchesBegan
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            let translation = CGSize(
                width: location.x - startTouchLocation.x,
                height: location.y - startTouchLocation.y
            )

            // Detect significant movement, making it not a tap
            if abs(translation.width) > 10 || abs(translation.height) > 10 {
                isTap = false
            }

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

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)

            let touchData = TouchData(
                type: touch.type,
                location: location,
                startLocation: startTouchLocation,
                translation: .zero,
                predictedEndLocation: location,
                predictedEndTranslation: .zero,
                time: Date()
            )

            if isTap {
                onTap?(touchData)
            } else {
                onTouchEnd?(touchData)
            }
        }
    }
}

struct TouchData {
    var type: UITouch.TouchType
    var location: CGPoint
    var startLocation: CGPoint
    var translation: CGSize
    var predictedEndLocation: CGPoint
    var predictedEndTranslation: CGSize
    var time: Date
}
