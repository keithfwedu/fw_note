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
    @State private var isHorizontalScroll: Bool = true // State variable for scroll direction

    var body: some View {
        HStack {
            HStack(spacing: 10) { // Fixed spacing between items
                // Save PDF Button
                Button(action: savePDF) {
                    Image(systemName: "square.and.arrow.down")
                }
                .frame(width: 40, height: 40)

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
                    Slider(value: $canvasState.penSize, in: 3...10, step: 0.1) {
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

                Button(action: redoAction) {
                    Image(systemName: "arrow.uturn.forward")
                }
                .frame(width: 40)

                // Scroll Direction Button
                Button(action: toggleDisplayDirection) {
                    Image(systemName: isHorizontalScroll ? "arrow.left.and.right" : "arrow.up.and.down")
                }
                .frame(width: 40, height: 40)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .accessibilityLabel("Change Scroll Direction")
            }
            .padding()
            .background(Color(UIColor.systemGray6)) // Toolbar background
        }
    }

    // Mock functions
    func savePDF() { print("Save PDF") }
    func selectPenTool() {
        print("selectPenTool")
        canvasState.selectionModeIndex = CanvasMode.draw.rawValue
    }
    func toggleLaserMode() {
        print("toggleLaserMode")
        canvasState.selectionModeIndex = CanvasMode.laser.rawValue
    }
    func selectEraserTool() {
        print("selectEraserTool")
        canvasState.selectionModeIndex = CanvasMode.eraser.rawValue
    }
    func selectEraserFillTool() { print("selectEraserFillTool") }
    func selectLassorTool() {
        print("selectLassorTool")
        canvasState.selectionModeIndex = CanvasMode.lasso.rawValue
    }
    func addImage() {
        print("addImage")
        let newImageObj = ImageObj(
            id: UUID(),
            path: nil,
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 100, height: 100)
        )
        
        noteFile.notePages[canvasState.currentPageIndex].imageStack.append(newImageObj)
        noteFile.addToUndo(
            pageIndex: self.canvasState.currentPageIndex, lineStack: self.noteFile.notePages[self.canvasState.currentPageIndex].lineStack,
            imageStack: self.noteFile.notePages[self.canvasState.currentPageIndex].imageStack)
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
        isHorizontalScroll.toggle()
        canvasState.displayDirection = isHorizontalScroll ? .horizontal : .vertical
        print("Scroll direction changed to \(canvasState.displayDirection == .horizontal ? "Horizontal" : "Vertical")")
    }
}
