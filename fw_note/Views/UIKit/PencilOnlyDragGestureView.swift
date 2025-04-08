//
//  PencilOnlyDragGestureView.swift
//  fw_note
//
//  Created by Fung Wing on 7/4/2025.
//

import SwiftUI
import UIKit

struct PencilOnlyDragGestureView: UIViewRepresentable {
    var onChanged: (CGPoint) -> Void
    var onEnded: () -> Void

    func makeUIView(context: Context) -> PencilFilteringView {
        let view = PencilFilteringView()
        view.onChanged = onChanged
        view.onEnded = onEnded
        return view
    }

    func updateUIView(_ uiView: PencilFilteringView, context: Context) {
        // No updates required
    }

    class PencilFilteringView: UIView {
        var onChanged: ((CGPoint) -> Void)?
        var onEnded: (() -> Void)?

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first, touch.type == .pencil else { return }
            let location = touch.location(in: self)
            onChanged?(location)
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first, touch.type == .pencil else { return }
            let location = touch.location(in: self)
            onChanged?(location)
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first, touch.type == .pencil else { return }
            onEnded?()
        }
    }
}
