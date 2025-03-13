//
//  CanvasSettings.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import PencilKit
import SwiftUI

class CanvasSettings: ObservableObject {
    @Published var selectionModeIndex: Int = 0
    @Published var isCanvasInteractive: Bool = true

    @Published var currentDrawingLineID: UUID? = nil
    @Published var lastDrawPosition: CGPoint? = nil
    @Published var lastDragPosition: CGPoint? = nil

    @Published var selectionPath: [CGPoint] = []
    @Published var selectedImages: [UUID] = []
    @Published var selectedLines: [Line] = []
    @Published var isLassoCreated: Bool = false
    @Published var timerManager = TimerManager()

    @Published var lines: [Line] = []
    @Published var imageViews: [ImageView] = []

    // Undo/Redo Stacks
    @Published var undoStack: [(lines: [Line], imageViews: [ImageView])] = []
    @Published var redoStack: [(lines: [Line], imageViews: [ImageView])] = []

    // Max history size
    private let maxHistorySize = 50

    func saveStateForUndo() {
        // Save current state to undo stack
        undoStack.append((lines: lines, imageViews: imageViews))
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst()
        }

        // Clear redo stack when a new action is performed
        redoStack.removeAll()
    }

    func undo() {
        guard let lastState = undoStack.popLast() else { return }

        // Save current state to redo stack
        redoStack.append((lines: lines, imageViews: imageViews))
        if redoStack.count > maxHistorySize {
            redoStack.removeFirst()
        }

        // Restore the last state
        lines = lastState.lines
        imageViews = lastState.imageViews
    }

    func redo() {
        guard let nextState = redoStack.popLast() else { return }

        // Save current state to undo stack
        undoStack.append((lines: lines, imageViews: imageViews))
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst()
        }

        // Restore the next state
        lines = nextState.lines
        imageViews = nextState.imageViews
    }
}
