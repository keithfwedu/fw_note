//
//  CanvasSettings.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import PencilKit
import SwiftUI

struct CanvasState: Codable {
    let lines: [Line]
    let imageObjs: [ImageObj]
    let gifs: [Gif]
    let undoStack: [[Line]] // Simplified for encoding
    let redoStack: [[Line]] // Simplified for encoding
}

class CanvasSettings: ObservableObject {
    @Published var lines: [Line] = []
    @Published var imageObjs: [ImageObj] = []
    @Published var gifs: [Gif] = []
    
    @Published var selectionModeIndex: Int = 0
    @Published var isCanvasInteractive: Bool = true

    @Published var currentDrawingLineID: UUID? = nil
    @Published var touchPoint: CGPoint? = nil
    @Published var lastDrawPosition: CGPoint? = nil
    @Published var lastDragPosition: CGPoint? = nil

    @Published var selectionPath: [CGPoint] = []
    @Published var selectedImages: [UUID] = []
    @Published var selectedLines: [Line] = []
    @Published var isLassoCreated: Bool = false
    @Published var timerManager = TimerManager()
    @Published var isTouching: Bool = false
    

    // Undo/Redo Stacks
    @Published var undoStack: [(lines: [Line], imageObjs: [ImageObj])] = []
    @Published var redoStack: [(lines: [Line], imageObjs: [ImageObj])] = []

    // Max history size
    private let maxHistorySize = 50

    func saveStateForUndo() {
        // Save current state to undo stack
        undoStack.append((lines: lines, imageObjs: imageObjs))
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst()
        }

        // Clear redo stack when a new action is performed
        redoStack.removeAll()
    }

    func undo() {
        guard let lastState = undoStack.popLast() else { return }

        // Save current state to redo stack
        redoStack.append((lines: lines, imageObjs: imageObjs))
        if redoStack.count > maxHistorySize {
            redoStack.removeFirst()
        }

        // Restore the last state
        lines = lastState.lines
        imageObjs = lastState.imageObjs
    }

    func redo() {
        guard let nextState = redoStack.popLast() else { return }

        // Save current state to undo stack
        undoStack.append((lines: lines, imageObjs: imageObjs))
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst()
        }

        // Restore the next state
        lines = nextState.lines
        imageObjs = nextState.imageObjs
    }
    
    
    func saveCanvasState() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            // Create an instance of CanvasState
            let canvasState = CanvasState(
                lines: lines,
                imageObjs: imageObjs,
                gifs: gifs,
                undoStack: undoStack.map { $0.lines }, // Extract only lines for simplicity
                redoStack: redoStack.map { $0.lines }  // Extract only lines for simplicity
            )

            // Encode the canvasState struct
            let data = try encoder.encode(canvasState)
            let url = getDocumentsDirectory().appendingPathComponent("canvasState.json")
            try data.write(to: url)
            print("Canvas state saved!")
        } catch {
            print("Failed to save canvas state: \(error)")
        }
    }


    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func loadCanvasState() {
        let decoder = JSONDecoder()

        do {
            let url = getDocumentsDirectory().appendingPathComponent("canvasState.json")
            let data = try Data(contentsOf: url)
            let canvasState = try decoder.decode(CanvasState.self, from: data)

            // Restore properties
            lines = canvasState.lines
            imageObjs = canvasState.imageObjs
            gifs = canvasState.gifs
            undoStack = canvasState.undoStack.map { (lines: $0, imageObjs: []) } // Rebuild undo stack
            redoStack = canvasState.redoStack.map { (lines: $0, imageObjs: []) } // Rebuild redo stack

            print("Canvas state loaded!")
        } catch {
            print("Failed to load canvas state: \(error)")
        }
    }


}
