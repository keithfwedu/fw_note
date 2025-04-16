//
//  TimerManager.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import SwiftUI

class TimerManager {
    private var holdTimer: Timer?

    func cancelHoldTimer() {
        holdTimer?.invalidate()
        holdTimer = nil
    }

    func startHoldTimer(for position: CGPoint, onHold: @escaping (CGPoint) -> Void) {
        holdTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            DispatchQueue.main.async {
                onHold(position)
            }
        }
    }

    func setHoldTimer(currentPosition: CGPoint, onHold: @escaping (CGPoint) -> Void) {
        cancelHoldTimer()
        startHoldTimer(for: currentPosition, onHold: onHold)
    }
}
