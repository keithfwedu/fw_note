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
                // Scroll Direction Button
                Button(action: toggleDisplayDirection) {
                    Image(
                        systemName: canvasState.displayDirection == .vertical
                        ? "arrow.up.and.down": "arrow.left.and.right" )
                }
                .frame(width: 40, height: 40)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .accessibilityLabel("Change Scroll Direction")

                // Tool Buttons
                Button(action: selectPenTool) {
                    Image(systemName: "pencil")
                }
                .frame(width: 40, height: 40)
                .background(
                    canvasState.canvasMode == CanvasMode.draw
                        ? Color.blue.opacity(0.2) : Color.clear
                )
                .cornerRadius(8)

                Button(action: toggleLaserMode) {
                    Image(systemName: "rays")
                }
                .frame(width: 40, height: 40)
                .background(
                    canvasState.canvasMode == CanvasMode.laser
                        ? Color.blue.opacity(0.2) : Color.clear
                )
                .cornerRadius(8)

                Button(action: selectEraserTool) {
                    Image(systemName: "trash")
                }
                .frame(width: 40, height: 40)
                .background(
                    canvasState.canvasMode == CanvasMode.eraser
                        ? Color.blue.opacity(0.2) : Color.clear
                )
                .cornerRadius(8)

                Button(action: selectLassorTool) {
                    Image(systemName: "lasso")
                }
                .frame(width: 40, height: 40)
                .background(
                    canvasState.canvasMode == CanvasMode.lasso
                        ? Color.blue.opacity(0.2) : Color.clear
                )
                .cornerRadius(8)

                

                if canvasState.canvasMode != CanvasMode.laser {
                    Slider(value: $canvasState.penSize, in: 3...10, step: 0.1) {
                        Text("Tool Size")
                    }
                    .frame(width: 100)
                }

                // Conditional Color Picker
                if canvasState.canvasMode == CanvasMode.draw {
                    ColorPickerView(
                        initialColors: $canvasState.recentColors,  // Input five colors from another view
                        onChanged: { selectedColor in
                            canvasState.penColor = selectedColor
                        }

                    )
                }
                if canvasState.canvasMode == CanvasMode.eraser {
                    Picker("Eraser Mode", selection: $canvasState.eraseMode) {
                        Text("Rubber").tag(EraseMode.rubber)
                        Text("Erase Whole Path").tag(EraseMode.whole)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                }

                // Flexible Spacer
                Spacer()

                // Undo/Redo Buttons
               
                // Save PDF Button
                Button(action: savePDF) {
                    Image(systemName: "square.and.arrow.down")
                }
                .frame(width: 40, height: 40)
              
                // Flexible Spacer
                Spacer()
                Button(action: undoAction) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .frame(width: 40)
                Button(action: redoAction) {
                    Image(systemName: "arrow.uturn.forward")
                }
                .frame(width: 40)
                Button(action: addImage) {
                    Image(systemName: "photo")
                }
                .frame(width: 40, height: 40)
                .cornerRadius(8)
                .disabled(canvasState.canvasMode == CanvasMode.laser)
            }
            .padding()
            .background(Color(UIColor.systemGray6))  // Toolbar background
        }
    }

    // Mock functions
    func savePDF() { print("Save PDF") }
    func selectPenTool() {
        print("selectPenTool")
        canvasState.canvasMode = CanvasMode.draw
    }
    func toggleLaserMode() {
        print("toggleLaserMode")
        canvasState.canvasMode = CanvasMode.laser
    }
    func selectEraserTool() {
        print("selectEraserTool")
        canvasState.canvasMode = CanvasMode.eraser
    }
    func selectEraserFillTool() { print("selectEraserFillTool") }
    func selectLassorTool() {
        print("selectLassorTool")
        canvasState.canvasMode = CanvasMode.lasso
    }
    func addImage() {
        print("addImage")
  
        canvasState.showImagePicker.toggle()
    }
    func undoAction() {
        print("undoAction")
        noteFile.undo()
    }
    func redoAction() {
        print("redoAction")
        noteFile.redo()
    }

    func toggleDisplayDirection() {

        canvasState.displayDirection =
            canvasState.displayDirection == .horizontal
            ? .vertical : .horizontal
        
        
        print(
            "Scroll direction changed to \(canvasState.displayDirection == .horizontal ? "Horizontal" : "Vertical")"
        )
    }
}
