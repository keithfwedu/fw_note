//
//  CanvasState.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import PDFKit
import PencilKit
import SwiftUI

class CanvasState: ObservableObject {
    @Published var timerManager = TimerManager()
    @Published var currentPageIndex: Int = 0
    @Published var selectionModeIndex: Int = 0
    @Published var penSize: CGFloat = 3.0
    @Published var penColor: Color = .black
    @Published var recentColors: [Color] = []

    @Published var isCanvasInteractive: Bool = true
    @Published var isLaserCanvasInteractive: Bool = true
    @Published var displayDirection: PDFDisplayDirection = .vertical

    
}
