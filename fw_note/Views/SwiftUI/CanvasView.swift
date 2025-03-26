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
    @ObservedObject var noteFile: NoteFile
    @ObservedObject var notePage: NotePage
    

    @State var focusedID: UUID?
    @State var laserStack: [LineObj] = []
    @State var selectionPaths: [CGPoint] = []
    @State var selectedImageObjIds: [UUID] = []
    @State var selectedGifObjIds: [UUID] = []
    @State var selectedLineStack: [LineObj] = []

    @State var laserOpacity: Double = 1.0
    @State var laserTimerManager = LaserTimerManager()

    @State var lastDrawLaserPosition: CGPoint? = nil

    @State var isTouching: Bool = false
    @State var isLassoCreated: Bool = false

    @State var redrawTrigger = false

    @State var touchPoint: CGPoint? = nil
    @State var currentDrawingLineID: UUID? = nil
    @State var lastDrawPosition: CGPoint? = nil
    @State var lastDragPosition: CGPoint? = nil

    @State var imageStack: [ImageObj] = []

    @State private var cachedCanvasImage: CGImage? = nil

    var body: some View {
        ZStack {
            //For force refresh UI
            if redrawTrigger {
                VStack {}
            }

            // Add a dynamic circle that syncs with the touch position
            if self.touchPoint != nil && isTouching {
                Circle()
                    .stroke(Color.gray, lineWidth: 1)  // Thin border with red color
                    .background(Circle().fill(Color.clear))  // Optional: Make the circle transparent insid
                    .frame(
                        width: canvasState.penSize + 2,
                        height: canvasState.penSize + 2
                    )  // Circle size
                    .position(self.touchPoint!)  // Dynamically update circle position
            }

            GeometryReader { geometry in
                Canvas { context, size in

                    for canvasObj in notePage.canvasStack {
                        if let imageObj = canvasObj.imageObj {
                            if !imageObj.isAnimatedGIF,
                                let cgImage = imageObj.cgImage
                            {
                                // Existing logic for static images
                                context.withCGContext { cgContext in
                                    cgContext.saveGState()

                                    cgContext.translateBy(
                                        x: imageObj.position.x,
                                        y: imageObj.position.y)
                                    let radians =
                                        CGFloat(imageObj.angle) * .pi / 180
                                    cgContext.rotate(by: radians)
                                    cgContext.scaleBy(x: 1.0, y: -1.0)

                                    cgContext.draw(
                                        cgImage,
                                        in: CGRect(
                                            origin: CGPoint(
                                                x: -imageObj.size.width / 2,
                                                y: -imageObj.size.height / 2),
                                            size: imageObj.size
                                        ))

                                    cgContext.restoreGState()
                                }
                            }
                        }

                        // Handle LineObj
                        if let line = canvasObj.lineObj {
                            var path = Path()
                            path.addLines(line.points)

                            if selectedLineStack.contains(where: {
                                $0.id == line.id
                            }) {
                                context.stroke(
                                    path, with: .color(.blue),
                                    style: StrokeStyle(
                                        lineWidth: line.lineWidth)
                                )
                            } else {
                                if line.mode == .draw {
                                    context.blendMode = .normal
                                    context.stroke(
                                        path, with: .color(line.color),
                                        style: StrokeStyle(
                                            lineWidth: line.lineWidth)
                                    )
                                } else if line.mode == .eraser {
                                    context.blendMode = .clear
                                    context.stroke(
                                        path, with: .color(line.color),
                                        style: StrokeStyle(
                                            lineWidth: line.lineWidth)
                                    )
                                }
                            }
                        }
                    }

                    // Draw selection path if in select mode
                    if canvasState.canvasMode
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
                .frame(width: geometry.size.width, height: geometry.size.height)
                .border(.red, width: 1)
                .onAppear {
                    redrawTrigger.toggle()
                }
                .allowsHitTesting(true)  // Toggle interaction
                .onChange(of: canvasState.canvasMode) {
                    newMode in
                    handleModeChange(mode: newMode)
                }
                .onChange(of: notePage.canvasStack) { newStack in
                    imageStack = newStack.compactMap { $0.imageObj }
                    print("change2")
                }
                .gesture(
                    DragGesture(minimumDistance: 0)  // Handles both taps and drags
                        .onChanged { value in
                            focusedID = nil

                            if value.translation == .zero {
                                // Handle as a tap gesture
                                handleTap(at: value.startLocation)
                            } else {
                                // Handle as a drag gesture
                                handleDragChange(dragValue: value)
                            }

                            //  handleDragChange(dragValue: value)
                        }
                        .onEnded { value in
                            handleDragEnded()  // Finalize drag action
                        }
                )
                .drawingGroup()
                /*.onDrop(of: ["public.image"], isTargeted: nil) { providers in
                    handleDrop(providers: providers)
                }*/

                ForEach($imageStack, id: \.id) { imageObj in

                    InteractiveImageView(
                        imageObj: imageObj,
                        selectMode: .constant(
                            canvasState.canvasMode != CanvasMode.lasso),  // Avoid binding if it's derived
                        isFocused: .constant(focusedID == imageObj.id),
                        frameSize: geometry.size,
                        onTap: { id in
                            focusedID = id
                        },
                        onRemove: handleOnRemove,
                        afterMove: handleUndo,
                        afterScale: handleUndo,
                        afterRotate: handleUndo,
                        onChanged: { id, imageObj in
                            if let index = notePage.canvasStack.firstIndex(
                                where: { $0.imageObj?.id == id })
                            {
                                notePage.canvasStack[index].imageObj = imageObj

                            }
                        }
                    )

                }.clipped()
            }
            Canvas { context, size in

                for laser in laserStack {
                    var path = Path()
                    path.addLines(laser.points)

                    // Simulate the glow effect with a red aura
                    context.blendMode = .plusLighter  // Additive blending for glow effects

                    context.stroke(
                        path,
                        with: .color(Color.red.opacity(laserOpacity)),
                        style: StrokeStyle(
                            lineWidth: 9, lineCap: .round, lineJoin: .round)
                    )

                    // Render the core white laser beam
                    context.blendMode = .normal
                    context.stroke(
                        path,
                        with: .color(.white.opacity(laserOpacity)),
                        style: StrokeStyle(
                            lineWidth: 5, lineCap: .round, lineJoin: .round)
                    )
                }

            }.allowsHitTesting(false)

        }
        .background(.blue.opacity(0.1))
        .onTapGesture {
            focusedID = nil  // Reset focus if background is tapped
        }.onAppear {
            noteFile.addToUndo(
                pageIndex: self.pageIndex,
                canvasStack: self.notePage.canvasStack
            )
        }

    }

    func handleOnTap(id: UUID) {
        focusedID = id
    }

    func handleOnRemove(id: UUID) {
        if let index = notePage.canvasStack.firstIndex(where: {
            $0.imageObj?.id == id
        }) {
            notePage.canvasStack.remove(at: index)
            noteFile.addToUndo(
                pageIndex: pageIndex, canvasStack: notePage.canvasStack)
        }
    }

    func handleUndo(id: UUID) {
        noteFile.addToUndo(
            pageIndex: self.pageIndex,
            canvasStack: self.notePage.canvasStack)
    }

    // Modularized Tap Handling Function
    private func handleTap(at location: CGPoint) {

        // Perform hit-testing for images in canvasStack
        for canvasObj in notePage.canvasStack {
            if let imageObj = canvasObj.imageObj {
                let rect = CGRect(
                    x: imageObj.position.x - imageObj.size.width / 2,
                    y: imageObj.position.y - imageObj.size.height / 2,
                    width: imageObj.size.width,
                    height: imageObj.size.height
                )

                if rect.contains(location) {
                    print("Tapped on image: \(imageObj)")
                    focusedID = imageObj.id

                    // Exit early after finding the tapped image
                    return
                }
            }
        }

    }

    /* private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            // Check for a valid "public.image" type
            if provider.hasItemConformingToTypeIdentifier("public.image") {
                // Load the UIImage object directly
                provider.loadObject(ofClass: UIImage.self) { item, error in
                    guard error == nil, let uiImage = item as? UIImage else {
                        print(
                            "Failed to load image: \(String(describing: error))"
                        )
                        return
                    }

                    // Perform UI updates on the main thread
                    DispatchQueue.main.async {
                        // Save the image and create an ImageObj
                        if let imagePath = saveImageToDocuments(
                            image: uiImage,
                            targetSize: CGSize(width: 500, height: 500))
                        {
                            let newImageObj = ImageObj(
                                id: UUID(),
                                path: imagePath,
                                position: CGPoint(x: 100, y: 100),  // Example position
                                size: CGSize(width: 100, height: 100)  // Example size
                            )

                            let newCanvasObj = CanvasObj(imageObj: newImageObj);
                            notePage.canvasStack.append(newCanvasObj)
                            noteFile.addToUndo(
                                pageIndex: pageIndex, lineStack: nil,
                                imageStack: notePage.imageStack
                            )
                        }
                    }
                }
                return true  // Successfully handled the provider
            }
        }
        return false  // No valid providers were processed
    }

    private func saveImageToDocuments(image: UIImage, targetSize: CGSize? = nil)
        -> String?
    {
        // Resize the image if a target size is provided
        let resizedImage =
            targetSize != nil
            ? resizeImage(image: image, targetSize: targetSize!) : image

        // Convert the image to PNG data (to preserve transparency)
        guard let data = resizedImage.pngData() else { return nil }

        let filename = UUID().uuidString + ".png"  // Use PNG file format
        let fileURL = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)

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

        let newSize = CGSize(
            width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(origin: .zero, size: newSize)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage ?? image
    }*/

    private func handleModeChange(
        mode: CanvasMode
    ) {

        print("Mode changed to \(mode).")
        switch mode {
        case .draw:
            resetSelection()
        case .eraser:
            resetSelection()
        case .lasso:
            print("Erase Mode")
        case .laser:
            resetSelection()
        }
    }

    private func handleDragChange(dragValue: DragGesture.Value) {
        self.isTouching = true
        self.touchPoint = dragValue.location

        switch canvasState.canvasMode {
        case .draw:  // Draw Mode
            handleDrawing(dragValue: dragValue)
        case .eraser:  // Erase Mode
            handleErasing(dragValue: dragValue)
        case .lasso:  // Select Mode
            handleSelection(dragValue: dragValue)
        case .laser:  // Laser Mode
            handleLaser(dragValue: dragValue)
        }

    }

    private func handleDragEnded() {
        print("Gesture Ended")
        lastDrawPosition = nil
        lastDrawLaserPosition = nil
        isTouching = false

        switch canvasState.canvasMode {
        case .draw:  // Draw Mode
            lastDragPosition = nil
            canvasState.timerManager.cancelHoldTimer()
            noteFile.addToUndo(
                pageIndex: pageIndex, canvasStack: self.notePage.canvasStack)
        case .eraser:  // Erase Mode
            lastDragPosition = nil
            noteFile.addToUndo(
                pageIndex: pageIndex, canvasStack: self.notePage.canvasStack)
        case .lasso:  // Select Mode
            if !selectionPaths.isEmpty
                && isLassoCreated == false
            {
                let lineStack = notePage.canvasStack.compactMap { $0.lineObj }
                let imageStack = notePage.canvasStack.compactMap { $0.imageObj }

                let hasSelectedItems: Bool =
                    !selectedLineStack.isEmpty
                    || !selectedImageObjIds.isEmpty
                isLassoCreated = hasSelectedItems
                selectedLineStack =
                    LassoToolHelper.getSelectedLines(
                        selectionPath: selectionPaths,
                        lines: lineStack)
                selectedImageObjIds =
                    LassoToolHelper.getSelectedImages(
                        selectionPath: selectionPaths,
                        images: imageStack)
                selectionPaths =
                    LassoToolHelper.createSelectionBounds(
                        imageStack: imageStack,
                        selectedLines: selectedLineStack,
                        selectedImages: selectedImageObjIds)
            }
        case .laser:  // Laser Mode
            laserTimerManager.setLaserTimer(onFadout: {
                if lastDrawLaserPosition == nil {
                    fadeOutLasers()
                }
            })

        }

    }

    private func fadeOutLasers() {
        laserOpacity = 1
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            laserOpacity -= 0.3

            if laserOpacity <= 0 {
                laserOpacity = 1.0
                timer.invalidate()
                laserStack = []  // Clear the stack when all lasers have faded
            }
        }
    }

    private func findCurrentDrawingLine() -> LineObj? {
        guard let drawingLineID = currentDrawingLineID else {
            return nil
        }
        let lineStack = notePage.canvasStack.compactMap { $0.lineObj }
        return lineStack.first(where: { $0.id == drawingLineID })
    }

    private func handleDrawing(dragValue: DragGesture.Value) {
        if lastDrawPosition == nil {
            // Start a new stroke when drag begins
            print("First drag detected for a new stroke")
            let newLineObj = LineObj(
                color: canvasState.penColor,
                points: [dragValue.location],
                lineWidth: canvasState.penSize,
                mode: .draw
            )

            let newCanvasObj = CanvasObj(lineObj: newLineObj, imageObj: nil)
            notePage.canvasStack.append(newCanvasObj)  // Add a new line
            currentDrawingLineID = newLineObj.id
        } else {
            // Add points to the current stroke
            print("drag detected for a new stroke2")
            if let lastCanvasWithLine = notePage.canvasStack.last(where: {
                $0.lineObj != nil
            }),
                let lastLine = lastCanvasWithLine.lineObj
            {
                let interpolatedPoints = PointHelper.interpolatePoints(
                    from: lastLine.points.last ?? dragValue.location,
                    to: dragValue.location
                )
                if let lastIndex = notePage.canvasStack.lastIndex(where: {
                    $0.id == lastCanvasWithLine.id
                }) {
                    notePage.canvasStack[lastIndex].lineObj?.points.append(
                        contentsOf: interpolatedPoints)
                }
            }
        }

        // Update hold detection logic for the latest position
        if lastDrawPosition != nil {
            if PointHelper.distance(
                lastDrawPosition!, dragValue.location) > 5.0
            {
                print("set hold timer")
                lastDrawPosition = dragValue.location
                canvasState.timerManager.setHoldTimer(
                    currentPosition: dragValue.location
                ) {
                    position in

                    guard let line = findCurrentDrawingLine() else { return }
                    processLineForTransformation(line)

                }

            }
        } else {
            lastDrawPosition = dragValue.location
        }
    }

    private func processLineForTransformation(_ line: LineObj) {
        guard
            let index = notePage.canvasStack.firstIndex(where: {
                $0.lineObj?.id == line.id  // Check for the matching lineObj in canvasStack
            })
        else {
            print(
                "Line with id \(line.id) not found in canvasStack. No transformation applied."
            )
            return
        }

        guard let currentLineObj = notePage.canvasStack[index].lineObj else {
            print(
                "LineObj at index \(index) is nil. No transformation applied.")
            return
        }

        let shapePoints = ShapeHelper.lineToShape(currentLineObj)
        if !shapePoints.isEmpty {
            // Update the points of the lineObj in the canvasStack
            print("changed")

            notePage.canvasStack[index].lineObj?.points.removeAll()
            notePage.canvasStack[index].lineObj?.points.append(
                contentsOf: shapePoints)

            self.lastDrawPosition = nil  // Reset the last draw position
            redrawTrigger.toggle()
        }
    }

    private func handleLaser(dragValue: DragGesture.Value) {
        if lastDrawLaserPosition == nil {
            // Start a new stroke when drag begins
            print("First drag detected for a new Laser")
            let newLine = LineObj(
                color: Color.white,
                points: [dragValue.location],
                lineWidth: canvasState.penSize,
                mode: .draw
            )
            laserStack.append(newLine)  // Add a new line

        } else {
            // Add points to the current stroke
            print("drag detected for a new Laser")
            if let lastLine = laserStack.last {
                let interpolatedPoints = PointHelper.interpolatePoints(
                    from: lastLine.points.last ?? dragValue.location,
                    to: dragValue.location
                )
                let lastIndex: Int = laserStack.count - 1
                laserStack[lastIndex].points.append(
                    contentsOf: interpolatedPoints)
            }
        }

        lastDrawLaserPosition = dragValue.location

    }

    private func handleErasing(dragValue: DragGesture.Value) {
        if canvasState.eraseMode == EraseMode.whole {
            // Whole-line erasing: Remove entire CanvasObj if lineObj is erased
            notePage.canvasStack = EraseHelper.eraseLineObjs(
                canvasStack: notePage.canvasStack,
                dragValue: dragValue,
                eraserRadius: canvasState.penSize
            )
        } else {
            // Partial erasing: Update CanvasObj to remove specific points in lineObj
            notePage.canvasStack = EraseHelper.eraseLines(
                canvasStack: notePage.canvasStack,
                dragValue: dragValue,
                eraserRadius: canvasState.penSize
            )
        }
    }

    private func handleSelection(dragValue: DragGesture.Value) {

        let imageStack = notePage.canvasStack.compactMap { $0.imageObj }
        let hasSelectedItems: Bool =
            !selectedLineStack.isEmpty
            || !selectedImageObjIds.isEmpty
        if lastDragPosition == nil {
            print("First drag detected")
            resetSelection()  // Ensure there's no existing selection
            self.selectionPaths = [dragValue.location]  // Initialize selection path
            lastDragPosition = dragValue.location
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
                    imageStack: imageStack,
                    selectedLines: selectedLineStack,
                    selectedImages: selectedImageObjIds)

                // Move selected lines
                for i in 0..<selectedLineStack.count {
                    let updatedPoints = selectedLineStack[i].points
                        .map {
                            CGPoint(
                                x: $0.x + centerTranslation.width,
                                y: $0.y + centerTranslation.height
                            )
                        }
                    self.selectedLineStack[i].points = updatedPoints
                }

                // Move selected images
                for i in 0..<notePage.canvasStack.count {
                    if let imageObj = notePage.canvasStack[i].imageObj,
                        selectedImageObjIds.contains(imageObj.id)
                    {
                        notePage.canvasStack[i].imageObj?.position.x +=
                            centerTranslation.width
                        notePage.canvasStack[i].imageObj?.position.y +=
                            centerTranslation.height
                    }
                }

                selectionPaths =
                    LassoToolHelper.moveSelectionPath(
                        selectionPath: selectionPaths,
                        translation: centerTranslation
                    )

                // Update the original lines and images
                for selectedLine in selectedLineStack {
                    if let index = notePage.canvasStack.firstIndex(where: {
                        $0.lineObj?.id == selectedLine.id  // Match based on lineObj's ID
                    }) {
                        notePage.canvasStack[index].lineObj = selectedLine  // Update the lineObj
                    }
                }
            }
        } else {
            // Case 3: Dragging outside the selection area
            print("Dragging outside selection")
            if hasSelectedItems {
                print("reset session")
                resetSelection()  // Ensure there's no existing selection
                isLassoCreated = false
            }
            if !isLassoCreated {
                self.selectionPaths.append(dragValue.location)
            }  // Extend the selection path

        }

        lastDragPosition = dragValue.location
    }

    private func resetSelection() {
        selectedLineStack.removeAll()
        selectedImageObjIds.removeAll()
        selectionPaths.removeAll()
        isLassoCreated = false
    }
}
