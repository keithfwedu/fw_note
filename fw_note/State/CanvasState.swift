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
    //PDF State
    @Published var currentPageIndex: Int = 0
    @Published var currentProjectId: String? = nil

    //State
    @Published var timerManager = TimerManager()
    @Published var canvasMode: CanvasMode = CanvasMode.draw
    @Published var eraseMode: EraseMode = EraseMode.rubber
    
    
    @Published var showImagePicker: Bool = false
    @Published var isDragging: Bool = false
    
    @Published var canvasPool: [Int: AnyView] = [:]
    
    
    //Configs
    @Published var displayDirection: PDFDisplayDirection = .vertical
    @Published var penSize: CGFloat = 0.5
    @Published var penColor: Color = .black
    @Published var inputMode: InputMode = InputMode.both
    @Published var recentColors: [Color] = [Color.black, Color.blue, Color.red, Color.yellow, Color.green];

    func setPageIndex(_ index: Int) {
        self.currentPageIndex = index
    }
}
