//
//  LaserTimeManager.swift
//  fw_note
//
//  Created by Fung Wing on 25/3/2025.
//

import SwiftUI

class LaserTimerManager {
    private var laserTimer: Timer?

    func cancelLaserTimer() {
        laserTimer?.invalidate()
        laserTimer = nil
    }

    func startLaserTimer(onFadout: @escaping () -> Void) {
        laserTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            DispatchQueue.main.async {
                onFadout()
            }
        }
    }

    func setLaserTimer(onFadout: @escaping () -> Void) {
        print("Laser timer1")
        cancelLaserTimer()
        print("Laser timer2")
        startLaserTimer(onFadout: onFadout)
    }
}
