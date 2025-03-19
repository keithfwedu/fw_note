//
//  CanvasState.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import PencilKit
import SwiftUI


class CanvasState: ObservableObject {
    @Published var timerManager = TimerManager()
    @Published var currentPageIndex: Int = 0
    @Published var selectionModeIndex: Int = 0
    @Published var isTouching: Bool = false
    @Published var isLassoCreated: Bool = false
    @Published var isCanvasInteractive: Bool = true
    @Published var isLaserCanvasInteractive: Bool = true

    @Published var touchPoint: CGPoint? = nil
    @Published var currentDrawingLineID: UUID? = nil
    @Published var lastDrawPosition: CGPoint? = nil
    @Published var lastDragPosition: CGPoint? = nil

    @Published var selectionPath: [CGPoint] = []

    @Published var selectedImageObjIds: [UUID] = []
    @Published var selectedGifObjIds: [UUID] = []
    @Published var selectedLineObjs: [LineObj] = []

    // Reset all selection paths
    func clearSelection() {
        selectionPath.removeAll()
        selectedImageObjIds.removeAll()
        selectedGifObjIds.removeAll()
        selectedLineObjs.removeAll()
    }

    // Reset touch and drag states
    func clearTouchStates() {
        touchPoint = nil
        lastDrawPosition = nil
        lastDragPosition = nil
    }
}
