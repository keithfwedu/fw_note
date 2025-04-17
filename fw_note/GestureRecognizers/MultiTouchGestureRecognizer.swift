//
//  MultiTouchGestureRecognizer.swift
//  fw_note
//
//  Created by Alex Ng on 29/3/2025.
//

import UIKit

class MultiTouchGestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {
    var multiTouchHandler: ((Bool) -> Void)?  // Closure to handle multi-touch state updates

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        //print("Touches began: \(event.allTouches?.count ?? 0)")

        // Notify whether it's a multi-touch or single-touch gesture
        if let allTouches = event.allTouches {
            multiTouchHandler?(allTouches.count > 1)
            self.state = allTouches.count > 1 ? .began : .possible
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        if let allTouches = event.allTouches {
            multiTouchHandler?(allTouches.count > 1)
            self.state = allTouches.count > 1 ? .changed : .possible
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)

        // Notify that the gesture has ended
        multiTouchHandler?(false)
        self.state = .ended
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow simultaneous gesture recognition to enable multiple gestures
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Ensure this gesture can take priority when needed (optional)
        return false
    }
}
