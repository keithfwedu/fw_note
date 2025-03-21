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
    
    @State var selectionPaths: [CGPoint] = []
    @State var selectedImageObjIds: [UUID] = []
    @State var selectedGifObjIds: [UUID] = []
    @State var selectedLineObjs: [LineObj] = []


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
                    if selectedImageObjIds.contains(
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

                    if selectedLineObjs.contains(where: {
                        $0.id == line.id
                    }) {
                        context.stroke(
                            path, with: .color(.blue),
                            style: StrokeStyle(lineWidth: line.lineWidth))
                    } else {
                        if line.mode == .draw {
                            context.blendMode = .normal
                            context.stroke(
                                path, with: .color(line.color),
                                style: StrokeStyle(lineWidth: line.lineWidth))
                        } else if line.mode == .eraser {
                            context.blendMode = .clear
                            context.stroke(
                                path, with: .color(line.color),
                                style: StrokeStyle(lineWidth: line.lineWidth))
                        }
                    }
                }

                // Draw selection path if in select mode
                if CanvasMode(
                    rawValue: canvasState.selectionModeIndex)
                    == .lasso
                    && !selectionPaths.isEmpty
                {
                    var selectionDrawing = Path()
                    selectionDrawing.addLines(
                       selectionPaths)
                    selectionDrawing.closeSubpath()
                    context.stroke(
                        selectionDrawing, with: .color(.green),
                        style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
            }
            
            .allowsHitTesting(canvasState.isCanvasInteractive)  // Toggle interaction
            .onChange(of: canvasState.selectionModeIndex) {
                newModeIndex in
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
            .clipped()
            .background(Color.blue.opacity(0.1))
            .onDrop(of: ["public.image"], isTargeted: nil) { providers in
                                handleDrop(providers: providers)
                            }

            ForEach($notePage.imageObjs) { $imageView in
                InteractiveImageView( 
                    position: $imageView.position,
                    size: $imageView.size,
                    selectMode: Binding<Bool>(
                        get: { canvasState.selectionModeIndex != 2 },
                        set: { _ in }  // No-op setter since the condition is derived
                    ),
                    path: $imageView.path
                ).clipped()
            }
        }

    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            // Check for a valid "public.image" type
            if provider.hasItemConformingToTypeIdentifier("public.image") {
                // Load the UIImage object directly
                provider.loadObject(ofClass: UIImage.self) { item, error in
                    guard error == nil, let uiImage = item as? UIImage else {
                        print("Failed to load image: \(String(describing: error))")
                        return
                    }
                    
                    // Perform UI updates on the main thread
                    DispatchQueue.main.async {
                        // Save the image and create an ImageObj
                        if let imagePath = saveImageToDocuments(image: uiImage, targetSize: CGSize(width: 500, height: 500)) {
                            print("imagePath: \(imagePath)")
                            let newImageObj = ImageObj(
                                id: UUID(),
                                path: imagePath,
                                position: CGPoint(x: 100, y: 100), // Example position
                                size: CGSize(width: 100, height: 100) // Example size
                            )
                            notePage.imageObjs.append(newImageObj)
                        }
                    }
                }
                return true // Successfully handled the provider
            }
        }
        return false // No valid providers were processed
    }

    
    
    private func saveImageToDocuments(image: UIImage, targetSize: CGSize? = nil) -> String? {
        // Resize the image if a target size is provided
        let resizedImage = targetSize != nil ? resizeImage(image: image, targetSize: targetSize!) : image

        // Convert the image to PNG data (to preserve transparency)
        guard let data = resizedImage.pngData() else { return nil }

        let filename = UUID().uuidString + ".png" // Use PNG file format
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }
    
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(origin: .zero, size: newSize)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage ?? image
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
        case .laser:
            print("Laser Mode")
        }
    }

    private func handleDragChange(dragValue: DragGesture.Value) {
        print("drag")
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
            case .laser:  // Laser Mode
                print("Laser Mode")
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

                if !selectionPaths.isEmpty
                    && canvasState.isLassoCreated == false
                {
                    let hasSelectedItems: Bool =
                        !selectedLineObjs.isEmpty
                        || !selectedImageObjIds.isEmpty
                    canvasState.isLassoCreated = hasSelectedItems
                    selectedLineObjs =
                        LassoToolHelper.getSelectedLines(
                            selectionPath:selectionPaths,
                            lines: notePage.lineObjs)
                    selectedImageObjIds =
                        LassoToolHelper.getSelectedImages(
                            selectionPath: selectionPaths,
                            images: notePage.imageObjs)
                    selectionPaths =
                        LassoToolHelper.createSelectionBounds(
                            imageObjs: notePage.imageObjs,
                            selectedLines: selectedLineObjs,
                            selectedImages: selectedImageObjIds)
                }
            case .laser:  // Laser Mode
                print("Laser Mode")
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
                color: canvasState.penColor,
                points: [dragValue.location],
                lineWidth: canvasState.penSize,
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
            !selectedLineObjs.isEmpty
            || !selectedImageObjIds.isEmpty
        if canvasState.lastDragPosition == nil {
            print("First drag detected")
            resetSelection()  // Ensure there's no existing selection
            self.selectionPaths = [dragValue.location]  // Initialize selection path
            canvasState.lastDragPosition = dragValue.location
            return  // Exit early as this is the first touch point
        }

        let isCurrentlyInsideSelection = LassoToolHelper.isPointInsideSelection(
            selectionPaths,
            point: dragValue.location)

        if isCurrentlyInsideSelection {
            print("Dragging inside selection")
            if hasSelectedItems {

                let centerTranslation = LassoToolHelper.getCenterTranslation(
                    dragValue: dragValue,
                    imageObjs: notePage.imageObjs,
                    selectedLines: selectedLineObjs,
                    selectedImages: selectedImageObjIds)

                // Move selected lines
                for i in 0..<selectedLineObjs.count {
                    let updatedPoints = selectedLineObjs[i].points
                        .map {
                            CGPoint(
                                x: $0.x + centerTranslation.width,
                                y: $0.y + centerTranslation.height
                            )
                        }
                    self.selectedLineObjs[i].points = updatedPoints
                }

                // Move selected images
                for i in 0..<notePage.imageObjs.count {
                    if selectedImageObjIds.contains(
                        notePage.imageObjs[i].id)
                    {
                        notePage.imageObjs[i].position.x +=
                            centerTranslation.width
                        notePage.imageObjs[i].position.y +=
                            centerTranslation.height
                    }
                }

                selectionPaths =
                    LassoToolHelper.moveSelectionPath(
                        selectionPath: selectionPaths,
                        translation: centerTranslation
                    )

                // Update the original lines and images
                for selectedLine in selectedLineObjs {
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
                self.selectionPaths.append(dragValue.location)
            }  // Extend the selection path

        }

        canvasState.lastDragPosition = dragValue.location
    }

    private func resetSelection() {
        selectedLineObjs.removeAll()
        selectedImageObjIds.removeAll()
        selectionPaths.removeAll()
        canvasState.isLassoCreated = false
    }
}

