//
//  PencilDetectionView.swift
//  fw_note
//
//  Created by Fung Wing on 8/4/2025.
//

import SwiftUI
import UIKit

struct PencilDetectionView: UIViewRepresentable {
    var onTouchStart: (TouchData) -> Void
    var onTouchChange: (TouchData) -> Void
    var onTouchEnd: (TouchData) -> Void

    func makeUIView(context: Context) -> PencilTouchDetectingView {
        let view = PencilTouchDetectingView()
        view.onTouchStart = onTouchStart
        view.onTouchChange = onTouchChange
        view.onTouchEnd = onTouchEnd

        return view
    }

    func updateUIView(_ uiView: PencilTouchDetectingView, context: Context) {}

    class PencilTouchDetectingView: UIView {
        var onTouchStart: ((TouchData) -> Void)?
        var onTouchChange: ((TouchData) -> Void)?
        var onTouchEnd: ((TouchData) -> Void)?

        private var previousTouchLocation: CGPoint = .zero
        private var previousTimestamp: TimeInterval = 0

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            previousTouchLocation = location
            previousTimestamp = touch.timestamp

            let touchData = TouchData(
                type: touch.type,
                location: location,
                startLocation: location,
                translation: .zero,
                predictedEndLocation: location, // No prediction on begin
                predictedEndTranslation: .zero,
                time: Date()
            )
            onTouchStart?(touchData)
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            let translation = CGSize(
                width: location.x - previousTouchLocation.x,
                height: location.y - previousTouchLocation.y
            )

            // Predict the next location
            let timeDelta = touch.timestamp - previousTimestamp
            let velocity = CGSize(
                width: translation.width / CGFloat(timeDelta),
                height: translation.height / CGFloat(timeDelta)
            )
            let predictedEndLocation = CGPoint(
                x: location.x + velocity.width * 0.1, // Predict a short distance ahead
                y: location.y + velocity.height * 0.1
            )

            let predictedEndTranslation = CGSize(
                width: predictedEndLocation.x - location.x,
                height: predictedEndLocation.y - location.y
            )

            let touchData = TouchData(
                type: touch.type,
                location: location,
                startLocation: previousTouchLocation,
                translation: translation,
                predictedEndLocation: predictedEndLocation,
                predictedEndTranslation: predictedEndTranslation,
                time: Date()
            )

            onTouchChange?(touchData)
            previousTouchLocation = location
            previousTimestamp = touch.timestamp
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            print("touchesEnded");
            let touchData = TouchData(
                type: touch.type,
                location: location,
                startLocation: previousTouchLocation,
                translation: .zero,
                predictedEndLocation: location, // No prediction on end
                predictedEndTranslation: .zero,
                time: Date()
            )
            onTouchEnd?(touchData)
        }
        
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            print("touchesCancelled");
            let touchData = TouchData(
                type: touch.type,
                location: location,
                startLocation: previousTouchLocation,
                translation: .zero,
                predictedEndLocation: location,
                predictedEndTranslation: .zero,
                time: Date()
            )
            onTouchEnd?(touchData)
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
