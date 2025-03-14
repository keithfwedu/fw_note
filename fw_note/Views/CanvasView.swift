//
//  CanvasView.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import SwiftUI

struct CanvasView: View {

    @StateObject private var canvasSettings = CanvasSettings()
    
    var body: some View {
        VStack {
            HStack {
                // Mode Picker
                Picker("Mode:", selection: $canvasSettings.selectionModeIndex) {
                    Text("Draw mode")
                        .tag(0)
                        .foregroundColor(
                            canvasSettings.selectionModeIndex == 0
                                ? .blue : .primary)
                    Text("Eraser Mode")
                        .tag(1)
                        .foregroundColor(
                            canvasSettings.selectionModeIndex == 1
                                ? .blue : .primary)
                    Text("Select Mode")
                        .tag(2)
                        .foregroundColor(
                            canvasSettings.selectionModeIndex == 2
                                ? .blue : .primary)
                }
                .pickerStyle(.segmented)

                Button("Add Image") {
                    let newImageObj = ImageObj(
                        id: UUID(), position: CGPoint(x: 100, y: 100),
                        size: CGSize(width: 100, height: 100))
                    canvasSettings.imageObjs.append(newImageObj)
                }

                Button("Add Gif") {
                    let newGif = Gif(
                        id: UUID(), position: CGPoint(x: 100, y: 100),
                        size: CGSize(width: 100, height: 100))
                    canvasSettings.gifs.append(newGif)
                }

                Button("Reset Canvas") {
                    canvasSettings.imageObjs = []
                    canvasSettings.gifs = []
                    canvasSettings.lines = []
                    canvasSettings.selectionPath = []
                    canvasSettings.selectedImages = []
                    canvasSettings.selectedLines = []
                }
                
                Button("Save") {
                    canvasSettings.saveCanvasState()
                }

                Button("Load") {
                    canvasSettings.loadCanvasState()
                }

                Button("Undo") {
                    canvasSettings.undo()
                }
                .disabled($canvasSettings.undoStack.isEmpty)  // Disable if no undo actions

                Button("Redo") {
                    canvasSettings.redo()
                }
                .disabled(canvasSettings.redoStack.isEmpty)

                Button(
                    canvasSettings.isCanvasInteractive
                        ? "Disable Canvas" : "Enable Canvas"
                ) {
                    canvasSettings.isCanvasInteractive.toggle()
                }
                .padding(.leading, 20)

            }

            VStack {
                ZStack {
                    // Add a dynamic circle that syncs with the touch position
                    if(canvasSettings.touchPoint != nil && canvasSettings.isTouching) {
                        Circle()
                            .stroke(Color.gray, lineWidth: 0.5) // Thin border with red color
                            .background(Circle().fill(Color.clear)) // Optional: Make the circle transparent insid
                            .frame(width: 8+5, height: 8+5) // Circle size
                            .position(canvasSettings.touchPoint!) // Dynamically update circle position
                    }

                    Canvas { context, size in

                        for image in canvasSettings.imageObjs {

                            var rectPath = Path()
                            rectPath.addRect(image.rect)

                            // Fill the rectangle with a color
                            context.fill(rectPath, with: .color(.gray))  // Replace .gray with any color

                            // Highlight selected images
                            if canvasSettings.selectedImages.contains(
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
                        for line in canvasSettings.lines {
                            var path = Path()
                            path.addLines(line.points)

                            if canvasSettings.selectedLines.contains(where: {
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
                            rawValue: canvasSettings.selectionModeIndex)
                            == .lasso
                            && !canvasSettings.selectionPath.isEmpty
                        {
                            var selectionDrawing = Path()
                            selectionDrawing.addLines(
                                canvasSettings.selectionPath)
                            selectionDrawing.closeSubpath()
                            context.stroke(
                                selectionDrawing, with: .color(.green),
                                style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        }
                    }
                    .allowsHitTesting(canvasSettings.isCanvasInteractive)  // Toggle interaction
                    .onChange(of: canvasSettings.selectionModeIndex) {
                        oldModeIndex, newModeIndex in
                        handleModeChange(index: newModeIndex)
                    }
                    .gesture(
                        DragGesture()
                            .onChanged(handleDragChange)
                            .onEnded({ _ in handleDragEnded() })
                    )
                    .onAppear {
                        canvasSettings.saveStateForUndo()
                    }

                    ForEach($canvasSettings.imageObjs) { $imageView in
                        InteractiveImageView(
                            position: $imageView.position,
                            size: $imageView.size,
                            selectMode: Binding<Bool>(
                                get: { canvasSettings.selectionModeIndex != 2 },
                                set: { _ in } // No-op setter since the condition is derived
                            )
                        )
                    }
                }

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
        canvasSettings.touchPoint = dragValue.location
        canvasSettings.isTouching = true
        if let mode = CanvasMode(rawValue: canvasSettings.selectionModeIndex) {
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
        canvasSettings.lastDrawPosition = nil
        canvasSettings.isTouching = false

        if let mode = CanvasMode(rawValue: canvasSettings.selectionModeIndex) {
            switch mode {
            case .draw:  // Draw Mode
                canvasSettings.lastDragPosition = nil
                canvasSettings.timerManager.cancelHoldTimer()

            case .eraser:  // Erase Mode
                canvasSettings.lastDragPosition = nil

            case .lasso:  // Select Mode

                if !canvasSettings.selectionPath.isEmpty
                    && canvasSettings.isLassoCreated == false
                {
                    let hasSelectedItems: Bool =
                        !canvasSettings.selectedLines.isEmpty
                        || !canvasSettings.selectedImages.isEmpty
                    canvasSettings.isLassoCreated = hasSelectedItems
                    canvasSettings.selectedLines =
                        LassoToolHelper.getSelectedLines(
                            selectionPath: canvasSettings.selectionPath,
                            lines: canvasSettings.lines)
                    canvasSettings.selectedImages =
                        LassoToolHelper.getSelectedImages(
                            selectionPath: canvasSettings.selectionPath,
                            images: canvasSettings.imageObjs)
                    canvasSettings.selectionPath =
                        LassoToolHelper.createSelectionBounds(
                            imageObjs: canvasSettings.imageObjs,
                            selectedLines: canvasSettings.selectedLines,
                            selectedImages: canvasSettings.selectedImages)
                }
            }
            canvasSettings.saveStateForUndo()
        } else {
            print("Invalid mode selected.")
        }
    }

    private func findCurrentDrawingLine() -> Line? {
        guard let drawingLineID = canvasSettings.currentDrawingLineID else {
            return nil
        }
        return canvasSettings.lines.first(where: { $0.id == drawingLineID })
    }

    private func handleDrawing(dragValue: DragGesture.Value) {
        if canvasSettings.lastDrawPosition == nil {
            // Start a new stroke when drag begins
            print("First drag detected for a new stroke")
            let newLine = Line(
                color: .brown,
                points: [dragValue.location],
                mode: .draw
            )
            canvasSettings.lines.append(newLine)  // Add a new line
            canvasSettings.currentDrawingLineID = newLine.id
        } else {
            // Add points to the current stroke
            print("drag detected for a new stroke2")
            if let lastLine = canvasSettings.lines.last {
                let interpolatedPoints = PointHelper.interpolatePoints(
                    from: lastLine.points.last ?? dragValue.location,
                    to: dragValue.location
                )
                let lastIndex: Int = canvasSettings.lines.count - 1
                canvasSettings.lines[lastIndex].points.append(
                    contentsOf: interpolatedPoints)
            }
        }

        // Update hold detection logic for the latest position
        if canvasSettings.lastDrawPosition != nil {
            if PointHelper.distance(
                canvasSettings.lastDrawPosition!, dragValue.location) > 5.0
            {
                print("set hold timer")
                canvasSettings.lastDrawPosition = dragValue.location
                canvasSettings.timerManager.setHoldTimer(
                    currentPosition: dragValue.location
                ) {
                    position in

                    guard let line = findCurrentDrawingLine() else { return }
                    processLineForTransformation(line)
                }

            }
        } else {
            canvasSettings.lastDrawPosition = dragValue.location
        }
    }

    private func processLineForTransformation(_ line: Line) {
        guard
            let index = canvasSettings.lines.firstIndex(where: {
                $0.id == line.id
            })
        else {
            print(
                "Line with id \(line.id) not found. No transformation applied.")
            return
        }

        let shapePoints = ShapeHelper.lineToShape(line)
        if !shapePoints.isEmpty {
            canvasSettings.lines[index].points = shapePoints
            canvasSettings.lastDrawPosition = nil
        }
    }

    private func handleErasing(dragValue: DragGesture.Value) {
        canvasSettings.lines = EraseHelper.eraseLines(
            lines: canvasSettings.lines, dragValue: dragValue)
    }

    private func handleSelection(dragValue: DragGesture.Value) {
        let hasSelectedItems: Bool =
            !canvasSettings.selectedLines.isEmpty
            || !canvasSettings.selectedImages.isEmpty
        if canvasSettings.lastDragPosition == nil {
            print("First drag detected")
            resetSelection()  // Ensure there's no existing selection
            canvasSettings.selectionPath = [dragValue.location]  // Initialize selection path
            canvasSettings.lastDragPosition = dragValue.location
            return  // Exit early as this is the first touch point
        }

        let isCurrentlyInsideSelection = LassoToolHelper.isPointInsideSelection(
            canvasSettings.selectionPath,
            point: dragValue.location)

        if isCurrentlyInsideSelection {
            print("Dragging inside selection")
            if hasSelectedItems {

                let centerTranslation = LassoToolHelper.getCenterTranslation(
                    dragValue: dragValue,
                    imageObjs: canvasSettings.imageObjs,
                    selectedLines: canvasSettings.selectedLines,
                    selectedImages: canvasSettings.selectedImages)

                // Move selected lines
                for i in 0..<canvasSettings.selectedLines.count {
                    let updatedPoints = canvasSettings.selectedLines[i].points
                        .map {
                            CGPoint(
                                x: $0.x + centerTranslation.width,
                                y: $0.y + centerTranslation.height
                            )
                        }
                    canvasSettings.selectedLines[i].points = updatedPoints
                }

                // Move selected images
                for i in 0..<canvasSettings.imageObjs.count {
                    if canvasSettings.selectedImages.contains(
                        canvasSettings.imageObjs[i].id)
                    {
                        canvasSettings.imageObjs[i].position.x +=
                            centerTranslation.width
                        canvasSettings.imageObjs[i].position.y +=
                            centerTranslation.height
                    }
                }

                canvasSettings.selectionPath =
                    LassoToolHelper.moveSelectionPath(
                        selectionPath: canvasSettings.selectionPath,
                        translation: centerTranslation
                    )

                // Update the original lines and images
                for selectedLine in canvasSettings.selectedLines {
                    if let index = canvasSettings.lines.firstIndex(where: {
                        $0.id == selectedLine.id
                    }) {
                        canvasSettings.lines[index] = selectedLine
                    }
                }
            }
        } else {
            // Case 3: Dragging outside the selection area
            print("Dragging outside selection")
            if hasSelectedItems {
                print("reset session")
                resetSelection()  // Ensure there's no existing selection
                canvasSettings.isLassoCreated = false
            }
            if !canvasSettings.isLassoCreated {
                canvasSettings.selectionPath.append(dragValue.location)
            }  // Extend the selection path

        }

        canvasSettings.lastDragPosition = dragValue.location
    }

    private func resetSelection() {
        canvasSettings.selectedLines.removeAll()
        canvasSettings.selectedImages.removeAll()
        canvasSettings.selectionPath.removeAll()
        canvasSettings.isLassoCreated = false
    }
}
