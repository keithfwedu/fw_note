//
//  UndoManager.swift
//  fw_note
//
//  Created by Alex Ng on 10/4/2025.
//

import Foundation
import SwiftUI

class NoteUndoManager: ObservableObject {
    
    private var MAX_UNDO_STACK_SIZE = 50
    private var MAX_REDO_STACK_SIZE = 50

    private var noteFile: NoteFile
    @Published var undoStack: [ActionStack] = []
    @Published var redoStack: [ActionStack] = []
    @Published var initCanvasStack: [ActionStack] = []
    
    init(noteFile: NoteFile) {
        self.noteFile = noteFile
    }
    
    func addInitialCanvasStack(pageIndex: Int, canvasStack: [CanvasObj]) {
        let clonedCanvasStack = canvasStack.map{$0.clone()}
        let action = ActionStack(
            pageIndex: pageIndex,
            canvasStack: clonedCanvasStack
        )
        initCanvasStack.append(action)
    }
    
    func addToUndo(pageIndex: Int, canvasStack: [CanvasObj]?) {
        // Clone the canvasStack to create an independent copy
        let clonedCanvasStack = canvasStack?.map { $0.clone() }

        print("Add to undo: Page \(pageIndex), Canvas count \(clonedCanvasStack?.count ?? 0)")

        // Create a new ActionStack with the cloned canvasStack
        let action = ActionStack(
            pageIndex: pageIndex,
            canvasStack: clonedCanvasStack
        )

        // Check if undoStack exceeds MAX_UNDO_STACK_SIZE
        if undoStack.count >= MAX_UNDO_STACK_SIZE {
            // Save the first undoStack to initCanvasStack
            if let firstAction = undoStack.first {
                // Remove existing entries in initCanvasStack for the same pageIndex
                initCanvasStack.removeAll { $0.pageIndex == pageIndex }
                // Save the first undoStack entry to initCanvasStack
                initCanvasStack.append(firstAction)
            }
            
            // Remove the first stack from undoStack
            undoStack.removeFirst()
        }

        // Add the new action to the undo stack
        undoStack.append(action)
    }


    func undo() {
        guard let currentAction = undoStack.popLast() else {
            return
        }
        
        redoStack.append(currentAction)

        // Check if there is a previous action
        if let lastAction = undoStack.last {
            print("lastActioin: \(lastAction)")
            // Move current action to redo stack
         
            // Update stacks based on the last action
            updateStacks(for: lastAction)
            
            // Check if there is an action to undo
          

        } else {
          
            if undoStack.isEmpty {
                print("undoStack.isEmpty");
                let filteredActionStacks = initCanvasStack.filter { $0.pageIndex == 0 }

                updateStacks(for: filteredActionStacks.first!)
                /*initCanvasStack.forEach { (initCanvas) in
                    updateStacks(for: initCanvas)
                }*/
            }
        }

       
        
    }


    func redo() {
        guard let lastAction = redoStack.popLast() else {
            print("Nothing to redo")
            return
        }
        
        // Check if undoStack exceeds MAX_UNDO_STACK_SIZE
        if redoStack.count >= MAX_REDO_STACK_SIZE {
            redoStack.removeFirst()
        }
        // Remove the first stack from undoStack
        undoStack.append(lastAction)
        updateStacks(for: lastAction)
    }

    private func updateStacks(for action: ActionStack) {
        print(
            "Undoing action for pageIndex: \(action.pageIndex). \((action.canvasStack ?? []).count)"
        )
 
        if action.canvasStack != nil {
            print("undo canvasStack")
            noteFile.notePages[action.pageIndex].canvasStack = action.canvasStack!
        }
    }
}
