//
//  PencilDetectionView.swift
//  fw_note
//
//  Created by Fung Wing on 8/4/2025.
//

import SwiftUI
import UIKit

struct PencilDetectionView: UIViewRepresentable {
    @ObservedObject var noteFile: NoteFile
    var onTap: (TouchData, NoteFile?) -> Void
    var onTouchMove: (TouchData, NoteFile?) -> Void
    var onTouchEnd: (TouchData, NoteFile?) -> Void

    func makeUIView(context: Context) -> PencilTouchDetectingView {
        let view = PencilTouchDetectingView(
            noteFile: noteFile,
            onTap: onTap,
            onTouchMove: onTouchMove,
            onTouchEnd: onTouchEnd)
        return view
    }

    func updateUIView(_ uiView: PencilTouchDetectingView, context: Context) {}

    class PencilTouchDetectingView: UIView {
        @ObservedObject var noteFile: NoteFile
        var onTap: ((TouchData, NoteFile?) -> Void)?
        var onTouchMove: ((TouchData, NoteFile?) -> Void)?
        var onTouchEnd: ((TouchData, NoteFile?) -> Void)?

        private var startTouchLocation: CGPoint = .zero
        private var isTap: Bool = true
        
        init(noteFile: NoteFile, onTap: ((TouchData, NoteFile?) -> Void)? = nil, onTouchMove: ((TouchData, NoteFile?) -> Void)? = nil, onTouchEnd: ((TouchData, NoteFile?) -> Void)? = nil) {
            self.noteFile = noteFile
            self.onTap = onTap
            self.onTouchMove = onTouchMove
            self.onTouchEnd = onTouchEnd
            super.init(frame: .zero)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
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
            onTap?(touchData, noteFile ?? nil) // Optionally handle the tap in touchesBegan
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
            onTouchMove?(touchData, noteFile ?? nil)
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
                onTap?(touchData, noteFile ?? nil)
            } else {
                onTouchEnd?(touchData, noteFile ?? nil)
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
