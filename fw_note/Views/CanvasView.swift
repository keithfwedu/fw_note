//
//  CanvasView.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import SwiftUI

struct CanvasView: View {
    let pageIndex: Int
    @ObservedObject var canvasState: CanvasState
    @ObservedObject var notePage: NotePage

    var body: some View {
        ZStack {
            // Add a dynamic circle that syncs with the touch position
            if canvasState.touchPoint != nil && canvasState.isTouching {
                Circle()
                    .stroke(Color.gray, lineWidth: 0.5)  // Thin border with red color
                    .background(Circle().fill(Color.clear))  // Optional: Make the circle transparent insid
                    .frame(width: 8 + 5, height: 8 + 5)  // Circle size
                    .position(canvasState.touchPoint!)  // Dynamically update circle position
            }

            Canvas { context, size in

                for image in notePage.imageObjs {

                    var rectPath = Path()
                    rectPath.addRect(image.rect)

                    // Fill the rectangle with a color
                    context.fill(rectPath, with: .color(.gray))  // Replace .gray with any color

                    // Highlight selected images
                    if canvasState.selectedImageObjIds.contains(
                        image.id)
                    {
                        let selectionRect = image.rect.insetBy(
                            dx: -2, dy: -2)
                        var borderPath = Path()
                        borderPath.addRect(selectionRect)
                        context.stroke(
                            borderPath, with: .color(.blue),
                            style: StrokeStyle(lineWidth: 2))
                    }
                }

                // Draw all lines
                for line in notePage.lineObjs {
                    var path = Path()
                    path.addLines(line.points)

                    if canvasState.selectedLineObjs.contains(where: {
                        $0.id == line.id
                    }) {
                        context.stroke(
                            path, with: .color(.blue),
                            style: StrokeStyle(lineWidth: 8))
                    } else {
                        if line.mode == .draw {
                            context.blendMode = .normal
                            context.stroke(
                                path, with: .color(line.color),
                                style: StrokeStyle(lineWidth: 8))
                        } else if line.mode == .eraser {
                            context.blendMode = .clear
                            context.stroke(
                                path, with: .color(line.color),
                                style: StrokeStyle(lineWidth: 8))
                        }
                    }
                }

                // Draw selection path if in select mode
                if CanvasMode(
                    rawValue: canvasState.selectionModeIndex)
                    == .lasso
                    && !canvasState.selectionPath.isEmpty
                {
                    var selectionDrawing = Path()
                    selectionDrawing.addLines(
                        canvasState.selectionPath)
                    selectionDrawing.closeSubpath()
                    context.stroke(
                        selectionDrawing, with: .color(.green),
                        style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
            }
            .allowsHitTesting(canvasState.isCanvasInteractive)  // Toggle interaction
            .onChange(of: canvasState.selectionModeIndex) {
                oldModeIndex, newModeIndex in
                handleModeChange(index: newModeIndex)
            }
            .gesture(
                DragGesture()
                    .onChanged(handleDragChange)
                    .onEnded({ _ in handleDragEnded() })
            )
            .onAppear {
                //canvasState.saveToUndo(forPageIndex: pageIndex)
            }
            .background(Color.blue.opacity(0.1))

            ForEach($notePage.imageObjs) { $imageView in
                InteractiveImageView(
                    position: $imageView.position,
                    size: $imageView.size,
                    selectMode: Binding<Bool>(
                        get: { canvasState.selectionModeIndex != 2 },
                        set: { _ in }  // No-op setter since the condition is derived
                    )
                )
            }
        }

    }

    private func handleModeChange(
        index: Int
    ) {
        guard let newMode = CanvasMode(rawValue: index) else {
            return
        }
        print("Mode changed to \(newMode.rawValue).")
        switch newMode {
        case .draw:
            resetSelection()
        case .eraser:
            resetSelection()
        case .lasso:
            print("Erase Mode")
        }
    }

    private func handleDragChange(dragValue: DragGesture.Value) {
        canvasState.touchPoint = dragValue.location
        canvasState.isTouching = true
        if let mode = CanvasMode(rawValue: canvasState.selectionModeIndex) {
            switch mode {
            case .draw:  // Draw Mode
                handleDrawing(dragValue: dragValue)
            case .eraser:  // Erase Mode
                handleErasing(dragValue: dragValue)
            case .lasso:  // Select Mode
                handleSelection(dragValue: dragValue)
            }
        } else {
            print("Invalid mode selected.")
        }
    }

    private func handleDragEnded() {
        print("Erase Mode Gesture Ended")
        canvasState.lastDrawPosition = nil
        canvasState.isTouching = false

        if let mode = CanvasMode(rawValue: canvasState.selectionModeIndex) {
            switch mode {
            case .draw:  // Draw Mode
                canvasState.lastDragPosition = nil
                canvasState.timerManager.cancelHoldTimer()

            case .eraser:  // Erase Mode
                canvasState.lastDragPosition = nil

            case .lasso:  // Select Mode

                if !canvasState.selectionPath.isEmpty
                    && canvasState.isLassoCreated == false
                {
                    let hasSelectedItems: Bool =
                        !canvasState.selectedLineObjs.isEmpty
                        || !canvasState.selectedImageObjIds.isEmpty
                    canvasState.isLassoCreated = hasSelectedItems
                    canvasState.selectedLineObjs =
                        LassoToolHelper.getSelectedLines(
                            selectionPath: canvasState.selectionPath,
                            lines: notePage.lineObjs)
                    canvasState.selectedImageObjIds =
                        LassoToolHelper.getSelectedImages(
                            selectionPath: canvasState.selectionPath,
                            images: notePage.imageObjs)
                    canvasState.selectionPath =
                        LassoToolHelper.createSelectionBounds(
                            imageObjs: notePage.imageObjs,
                            selectedLines: canvasState.selectedLineObjs,
                            selectedImages: canvasState.selectedImageObjIds)
                }
            }
            //canvasState.saveStateForUndo()
        } else {
            print("Invalid mode selected.")
        }
    }

    private func findCurrentDrawingLine() -> LineObj? {
        guard let drawingLineID = canvasState.currentDrawingLineID else {
            return nil
        }
        return notePage.lineObjs.first(where: { $0.id == drawingLineID })
    }

    private func handleDrawing(dragValue: DragGesture.Value) {
        if canvasState.lastDrawPosition == nil {
            // Start a new stroke when drag begins
            print("First drag detected for a new stroke")
            let newLine = LineObj(
                color: .brown,
                points: [dragValue.location],
                mode: .draw
            )
            notePage.lineObjs.append(newLine)  // Add a new line
            canvasState.currentDrawingLineID = newLine.id
        } else {
            // Add points to the current stroke
            print("drag detected for a new stroke2")
            if let lastLine = notePage.lineObjs.last {
                let interpolatedPoints = PointHelper.interpolatePoints(
                    from: lastLine.points.last ?? dragValue.location,
                    to: dragValue.location
                )
                let lastIndex: Int = notePage.lineObjs.count - 1
                notePage.lineObjs[lastIndex].points.append(
                    contentsOf: interpolatedPoints)
            }
        }

        // Update hold detection logic for the latest position
        if canvasState.lastDrawPosition != nil {
            if PointHelper.distance(
                canvasState.lastDrawPosition!, dragValue.location) > 5.0
            {
                print("set hold timer")
                canvasState.lastDrawPosition = dragValue.location
                canvasState.timerManager.setHoldTimer(
                    currentPosition: dragValue.location
                ) {
                    position in

                    guard let line = findCurrentDrawingLine() else { return }
                    processLineForTransformation(line)
                }

            }
        } else {
            canvasState.lastDrawPosition = dragValue.location
        }
    }

    private func processLineForTransformation(_ line: LineObj) {
        guard
            let index = notePage.lineObjs.firstIndex(where: {
                $0.id == line.id
            })
        else {
            print(
                "Line with id \(line.id) not found. No transformation applied.")
            return
        }

        let shapePoints = ShapeHelper.lineToShape(line)
        if !shapePoints.isEmpty {
            notePage.lineObjs[index].points = shapePoints
            canvasState.lastDrawPosition = nil
        }
    }

    private func handleErasing(dragValue: DragGesture.Value) {
        notePage.lineObjs = EraseHelper.eraseLines(
            lines: notePage.lineObjs, dragValue: dragValue)
    }

    private func handleSelection(dragValue: DragGesture.Value) {
        let hasSelectedItems: Bool =
            !canvasState.selectedLineObjs.isEmpty
            || !canvasState.selectedImageObjIds.isEmpty
        if canvasState.lastDragPosition == nil {
            print("First drag detected")
            resetSelection()  // Ensure there's no existing selection
            canvasState.selectionPath = [dragValue.location]  // Initialize selection path
            canvasState.lastDragPosition = dragValue.location
            return  // Exit early as this is the first touch point
        }

        let isCurrentlyInsideSelection = LassoToolHelper.isPointInsideSelection(
            canvasState.selectionPath,
            point: dragValue.location)

        if isCurrentlyInsideSelection {
            print("Dragging inside selection")
            if hasSelectedItems {

                let centerTranslation = LassoToolHelper.getCenterTranslation(
                    dragValue: dragValue,
                    imageObjs: notePage.imageObjs,
                    selectedLines: canvasState.selectedLineObjs,
                    selectedImages: canvasState.selectedImageObjIds)

                // Move selected lines
                for i in 0..<canvasState.selectedLineObjs.count {
                    let updatedPoints = canvasState.selectedLineObjs[i].points
                        .map {
                            CGPoint(
                                x: $0.x + centerTranslation.width,
                                y: $0.y + centerTranslation.height
                            )
                        }
                    canvasState.selectedLineObjs[i].points = updatedPoints
                }

                // Move selected images
                for i in 0..<notePage.imageObjs.count {
                    if canvasState.selectedImageObjIds.contains(
                        notePage.imageObjs[i].id)
                    {
                        notePage.imageObjs[i].position.x +=
                            centerTranslation.width
                        notePage.imageObjs[i].position.y +=
                            centerTranslation.height
                    }
                }

                canvasState.selectionPath =
                    LassoToolHelper.moveSelectionPath(
                        selectionPath: canvasState.selectionPath,
                        translation: centerTranslation
                    )

                // Update the original lines and images
                for selectedLine in canvasState.selectedLineObjs {
                    if let index = notePage.lineObjs.firstIndex(where: {
                        $0.id == selectedLine.id
                    }) {
                        notePage.lineObjs[index] = selectedLine
                    }
                }
            }
        } else {
            // Case 3: Dragging outside the selection area
            print("Dragging outside selection")
            if hasSelectedItems {
                print("reset session")
                resetSelection()  // Ensure there's no existing selection
                canvasState.isLassoCreated = false
            }
            if !canvasState.isLassoCreated {
                canvasState.selectionPath.append(dragValue.location)
            }  // Extend the selection path

        }

        canvasState.lastDragPosition = dragValue.location
    }

    private func resetSelection() {
        canvasState.selectedLineObjs.removeAll()
        canvasState.selectedImageObjIds.removeAll()
        canvasState.selectionPath.removeAll()
        canvasState.isLassoCreated = false
    }
}
