//
//  CanvasState.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import PencilKit
import SwiftUI
import PDFKit

class CanvasState: ObservableObject {
    @Published var timerManager = TimerManager()
    @Published var currentPageIndex: Int = 0
    @Published var selectionModeIndex: Int = 0
    @Published var penSize: CGFloat = 1.0
    @Published var penColor: Color = .black
    @Published var recentColors: [Color] = []
    
    @Published var isCanvasInteractive: Bool = true
    @Published var isLaserCanvasInteractive: Bool = true
    @Published var displayDirection: PDFDisplayDirection = .vertical

    
    /*@Published var isTouching: Bool = false
    @Published var isLassoCreated: Bool = false

    @Published var touchPoint: CGPoint? = nil
    @Published var currentDrawingLineID: UUID? = nil
    @Published var lastDrawPosition: CGPoint? = nil
    @Published var lastDragPosition: CGPoint? = nil
   


    // Reset touch and drag states
    func clearTouchStates() {
        touchPoint = nil
        lastDrawPosition = nil
        lastDragPosition = nil
    }*/
}
