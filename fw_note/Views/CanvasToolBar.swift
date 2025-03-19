//
//  CanvasToolBar.swift
//  fw_note
//
//  Created by Fung Wing on 19/3/2025.
//

import SwiftUI

struct CanvasToolBar: View {
    @StateObject var noteFile: NoteFile
    @StateObject var canvasState: CanvasState
    
    var body: some View {
        HStack {
            // Mode Picker
            Picker("Mode:", selection: $canvasState.selectionModeIndex) {
                Text("Draw mode")
                    .tag(0)
                    .foregroundColor(
                        canvasState.selectionModeIndex == 0
                        ? .blue : .primary)
                Text("Eraser Mode")
                    .tag(1)
                    .foregroundColor(
                        canvasState.selectionModeIndex == 1
                        ? .blue : .primary)
                Text("Select Mode")
                    .tag(2)
                    .foregroundColor(
                        canvasState.selectionModeIndex == 2
                        ? .blue : .primary)
            }
            .pickerStyle(.segmented)
            
            Button("Add Image") {
                let newImageObj = ImageObj(
                    id: UUID(),
                    path: nil,
                    position: CGPoint(x: 100, y: 100),
                    size: CGSize(width: 100, height: 100))
                noteFile.notePages[canvasState.currentPageIndex].imageObjs.append(newImageObj)
            }
            
            Button("Add Gif") {
                let newGifObj = GifObj(
                    id: UUID(),
                    path: nil,
                    position: CGPoint(x: 100, y: 100),
                    size: CGSize(width: 100, height: 100))
                noteFile.notePages[canvasState.currentPageIndex].gifObjs.append(newGifObj)
            }
            
            Button("Reset Canvas") {
                noteFile.notePages[canvasState.currentPageIndex].imageObjs = []
                noteFile.notePages[canvasState.currentPageIndex].gifObjs = []
                noteFile.notePages[canvasState.currentPageIndex].lineObjs = []
                canvasState.selectionPath = []
                canvasState.selectedImageObjIds = []
                canvasState.selectedLineObjs = []
            }
            
            Button("Save") {
                
            }
            
            
            Button("Undo") {
                //canvasState.undo()
            }
            //.disabled($noteState.file.undoStack.isEmpty)  // Disable if no undo actions
            
            Button("Redo") {
                //canvasState.redo()
            }
            //.disabled($noteState.file.redoStack.isEmpty)
            
            Button(
                canvasState.isCanvasInteractive
                ? "Disable Canvas" : "Enable Canvas"
            ) {
                DispatchQueue.main.async {
                    canvasState.isCanvasInteractive.toggle()
                }
            }
            .padding(.leading, 20)
        }
        
    }
}
