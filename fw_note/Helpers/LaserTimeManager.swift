//
//  LaserTimeManager.swift
//  fw_note
//
//  Created by Fung Wing on 25/3/2025.
//

import SwiftUI

class LaserTimerManager {
    private var laserTimer: Timer?

    private func cancelLaserTimer() {
        //print("cancel laser timer")
        self.laserTimer?.invalidate()
        self.laserTimer = nil
    }

    private func startLaserTimer(onFadout: @escaping () -> Void) {
        self.laserTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { _ in
           
            DispatchQueue.main.async {
                self.cancelLaserTimer()
                onFadout()
            }
        }
    }

    func setLaserTimer(onFadout: @escaping () -> Void) {
        self.cancelLaserTimer()
        //print("New laser timer")
        self.startLaserTimer(onFadout: onFadout)
    }
}
