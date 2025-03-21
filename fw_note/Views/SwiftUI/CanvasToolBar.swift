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

            HStack(spacing: 10) {  // Fixed spacing between items
                // Save PDF Button
                Button(action: savePDF) {
                    Image(systemName: "square.and.arrow.down")
                }
                .frame(width: 40, height: 40)  // Fixed width for uniformity

                // Tool Buttons
                Button(action: selectPenTool) {
                    Image(systemName: "pencil")
                }
                .frame(width: 40, height: 40)
                .background(
                    canvasState.selectionModeIndex == CanvasMode.draw.rawValue
                        ? Color.blue.opacity(0.2) : Color.clear
                )
                .cornerRadius(8)
               

                Button(action: toggleLaserMode) {
                    Image(systemName: "rays")
                }
                .frame(width: 40, height: 40)
                .background(
                    canvasState.selectionModeIndex == CanvasMode.laser.rawValue
                        ? Color.blue.opacity(0.2) : Color.clear
                )
                .cornerRadius(8)
               

                Button(action: selectEraserTool) {
                    Image(systemName: "eraser")
                }
                .frame(width: 40, height: 40)
                .background(
                    canvasState.selectionModeIndex == CanvasMode.eraser.rawValue
                        ? Color.blue.opacity(0.2) : Color.clear
                )
                .cornerRadius(8)
                

                Button(action: selectEraserFillTool) {
                    Image(systemName: "eraser.fill")
                }
                .frame(width: 40, height: 40)
                .background(
                    canvasState.selectionModeIndex == CanvasMode.eraser.rawValue
                        ? Color.blue.opacity(0.2) : Color.clear
                )
                .cornerRadius(8)
                

                Button(action: selectLassorTool) {
                    Image(systemName: "lasso")
                }
                .frame(width: 40, height: 40)
                .background(
                    canvasState.selectionModeIndex == CanvasMode.lasso.rawValue
                        ? Color.blue.opacity(0.2) : Color.clear
                )
                .cornerRadius(8)
               

                Button(action: addImage) {
                    Image(systemName: "photo")
                }
                .frame(width: 40, height: 40)
                .cornerRadius(8)
                .disabled(canvasState.selectionModeIndex == CanvasMode.laser.rawValue)
                
                if canvasState.selectionModeIndex != CanvasMode.laser.rawValue {
                    Slider(value: $canvasState.penSize, in: 1...10, step: 0.1) {
                        Text("Tool Size")
                    }
                    .frame(width: 100)
                }
                // Conditional Color Picker
                if canvasState.selectionModeIndex == CanvasMode.draw.rawValue {
                           ColorPickerView(
                               selectedColor: $canvasState.penColor,
                               recentColors: $canvasState.recentColors
                           )
                       }
                // Flexible Spacer
                Spacer()

                // Undo/Redo Buttons
                Button(action: undoAction) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .frame(width: 40)
                //.disabled(settings.isShowLaserCanvas)

                Button(action: redoAction) {
                    Image(systemName: "arrow.uturn.forward")
                }
                .frame(width: 40)
                // .disabled(settings.isShowLaserCanvas)
            }
            .padding()
            .background(Color(UIColor.systemGray6))  // Toolbar background

            /*  Button("Add Gif") {
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
            }*/

        }

    }

    // Mock functions
    func savePDF() { print("Save PDF") }
    func selectPenTool() {
        print("selectPenTool")
        canvasState.selectionModeIndex = 0
    }
    func toggleLaserMode() {
        print("toggleLaserMode")
        canvasState.selectionModeIndex = 3
    }
    func selectEraserTool() {
        print("selectEraserTool")
        canvasState.selectionModeIndex = 1

    }
    func selectEraserFillTool() {
        print("selectEraserFillTool")

    }
    func selectLassorTool() {
        print("selectLassorTool")
        canvasState.selectionModeIndex = 2
    }
    func addImage() {
        print("addImage")
        let newImageObj = ImageObj(
            id: UUID(),
            path: nil,
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 100, height: 100))
        noteFile.notePages[canvasState.currentPageIndex].imageObjs.append(
            newImageObj)

    }
    func undoAction() {
        print("undoAction")
    }
    func redoAction() {
        print("redoAction")
    }
}
