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
    @State var laserStack:[LineObj] = []
    @State var selectionPaths: [CGPoint] = []
    @State var selectedImageObjIds: [UUID] = []
    @State var selectedGifObjIds: [UUID] = []
    @State var selectedLineStack: [LineObj] = []
    
    @State var laserOpacity: Double = 1.0
    @State var laserTimerManager = LaserTimerManager()
   
    @State var lastDrawLaserPosition: CGPoint? = nil
   

    @State var isTouching: Bool = false
    @State var isLassoCreated: Bool = false

    @State var touchPoint: CGPoint? = nil
    @State var currentDrawingLineID: UUID? = nil
    @State var lastDrawPosition: CGPoint? = nil
    @State var lastDragPosition: CGPoint? = nil

    var body: some View {
        ZStack {
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
                    
                    for laser in laserStack {
                        var path = Path()
                        path.addLines(laser.points)
                        
                        // Simulate the glow effect with a red aura
                        context.blendMode = .plusLighter  // Additive blending for glow effects
                      
                            context.stroke(
                                path,
                                with: .color(Color.red.opacity(laserOpacity)),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
                            )
                       
                        
                        // Render the core white laser beam
                        context.blendMode = .normal
                        context.stroke(
                            path,
                            with: .color(.white.opacity(laserOpacity)),
                            style: StrokeStyle(lineWidth: laser.lineWidth, lineCap: .round, lineJoin: .round)
                        )
                    }



                    /* for imageObj in notePage.imageStack {
                        if let imagePath = Bundle.main.path(forResource: "example", ofType: "png"),
                           let cgImage = UIImage(contentsOfFile: imagePath)?.cgImage {
                            let rect = CGRect(
                                x: imageObj.position.x - imageObj.size.width / 2,  // Center the image
                                y: imageObj.position.y - imageObj.size.height / 2,
                                width: imageObj.size.width,
                                height: imageObj.size.height
                            )

                            context.withCGContext { cgContext in
                                // Save the current state of CGContext
                                cgContext.saveGState()

                                // Translate to the center of the image
                                cgContext.translateBy(x: imageObj.position.x, y: imageObj.position.y)

                                // Normalize the angle to 0–360
                                var normalizedAngle = imageObj.angle.truncatingRemainder(dividingBy: 360)
                                if normalizedAngle < 0 {
                                    normalizedAngle += 360
                                }

                                // Convert to radians
                                let radians = CGFloat(normalizedAngle) * .pi / 180

                                // Apply rotation (in radians)
                                cgContext.rotate(by: radians)

                                // Flip the Y-axis to correct UIImage flipping
                                cgContext.scaleBy(x: 1.0, y: -1.0)

                                // Draw the image centered around (0, 0)
                                cgContext.draw(cgImage, in: CGRect(
                                    origin: CGPoint(x: -rect.size.width / 2, y: -rect.size.height / 2),
                                    size: rect.size
                                ))

                                // Restore CGContext state
                                cgContext.restoreGState()
                            }
                        }
                    }*/

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
                .background(.blue.opacity(0.1))
                .allowsHitTesting(canvasState.isCanvasInteractive)  // Toggle interaction
                .onChange(of: canvasState.selectionModeIndex) {
                    newModeIndex in
                    handleModeChange(index: newModeIndex)
                }

                .gesture(
                    DragGesture(minimumDistance: 0)  // Handles both taps and drags
                        .onChanged { value in
                            focusedID = nil

                            /*if value.translation == .zero {
                                // Handle as a tap gesture
                                handleTap(at: value.startLocation)
                            } else {
                                // Handle as a drag gesture
                                handleDragChange(dragValue: value)
                            }*/

                            handleDragChange(dragValue: value)
                        }
                        .onEnded { value in
                            handleDragEnded()  // Finalize drag action
                        }
                )

                .onDrop(of: ["public.image"], isTargeted: nil) { providers in
                    handleDrop(providers: providers)
                }
                .drawingGroup()
                .clipped()

                ForEach($notePage.imageStack, id: \.id) { $imageObj in
                    InteractiveImageView(
                        imageObj: $imageObj,
                        selectMode: .constant(
                            canvasState.selectionModeIndex != 2),  // Avoid binding if it's derived
                        isFocused: .constant(focusedID == $imageObj.id),
                        frameSize: geometry.size,
                        onTap: { id in
                            focusedID = id

                        },
                        onRemove: { id in
                            if let index = notePage.imageStack.firstIndex(
                                where: {
                                    $0.id == imageObj.id
                                })
                            {
                                notePage.imageStack.remove(at: index)
                                noteFile.addToUndo(
                                    pageIndex: self.pageIndex,
                                    lineStack: self.notePage.lineStack,
                                    imageStack: self.notePage.imageStack)

                            }
                        },
                        afterMove: { id in
                            noteFile.addToUndo(
                                pageIndex: self.pageIndex,
                                lineStack: self.notePage.lineStack,
                                imageStack: self.notePage.imageStack)
                        },
                        afterScale: { id in
                            noteFile.addToUndo(
                                pageIndex: self.pageIndex,
                                lineStack: self.notePage.lineStack,
                                imageStack: self.notePage.imageStack)
                        },
                        afterRotate: { id in
                            noteFile.addToUndo(
                                pageIndex: self.pageIndex,
                                lineStack: self.notePage.lineStack,
                                imageStack: self.notePage.imageStack)
                        }
                    )

                }.clipped()

                Canvas { context, size in

                    // Draw all lines
                    for line in notePage.lineStack {
                        var path = Path()
                        path.addLines(line.points)

                        if selectedLineStack.contains(where: {
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
                                    style: StrokeStyle(
                                        lineWidth: line.lineWidth))
                            } else if line.mode == .eraser {
                                context.blendMode = .clear
                                context.stroke(
                                    path, with: .color(line.color),
                                    style: StrokeStyle(
                                        lineWidth: line.lineWidth))
                            }
                        }
                    }
                    
                    
                    

                }.allowsHitTesting(false)

            }

        }.onTapGesture {
            focusedID = nil  // Reset focus if background is tapped
        }.onAppear {
            noteFile.addToUndo(
                pageIndex: self.pageIndex, lineStack: self.notePage.lineStack,
                imageStack: self.notePage.imageStack)
        }
    }

    // Modularized Tap Handling Function
    private func handleTap(at location: CGPoint) {

        // Perform hit-testing for images
        for imageObj in notePage.imageStack {
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

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
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
                            notePage.imageStack.append(newImageObj)
                            noteFile.addToUndo(
                                pageIndex: pageIndex, lineStack: nil,
                                imageStack: notePage.imageStack)
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

        self.touchPoint = dragValue.location

        isTouching = true
        if let mode = CanvasMode(rawValue: canvasState.selectionModeIndex) {
            switch mode {
            case .draw:  // Draw Mode
                handleDrawing(dragValue: dragValue)
            case .eraser:  // Erase Mode
                handleErasing(dragValue: dragValue)
            case .lasso:  // Select Mode
                handleSelection(dragValue: dragValue)
            case .laser:  // Laser Mode
                handleLaser(dragValue: dragValue)
            }
        } else {
            print("Invalid mode selected.")
        }
    }

    private func handleDragEnded() {
        print("Erase Mode Gesture Ended")
        lastDrawPosition = nil
        lastDrawLaserPosition = nil
        isTouching = false

        if let mode = CanvasMode(rawValue: canvasState.selectionModeIndex) {
            switch mode {
            case .draw:  // Draw Mode
                lastDragPosition = nil
                canvasState.timerManager.cancelHoldTimer()
                noteFile.addToUndo(
                    pageIndex: pageIndex, lineStack: notePage.lineStack,
                    imageStack: nil)
            case .eraser:  // Erase Mode
                lastDragPosition = nil
                noteFile.addToUndo(
                    pageIndex: pageIndex, lineStack: notePage.lineStack,
                    imageStack: nil)
            case .lasso:  // Select Mode
                if !selectionPaths.isEmpty
                    && isLassoCreated == false
                {
                    let hasSelectedItems: Bool =
                        !selectedLineStack.isEmpty
                        || !selectedImageObjIds.isEmpty
                    isLassoCreated = hasSelectedItems
                    selectedLineStack =
                        LassoToolHelper.getSelectedLines(
                            selectionPath: selectionPaths,
                            lines: notePage.lineStack)
                    selectedImageObjIds =
                        LassoToolHelper.getSelectedImages(
                            selectionPath: selectionPaths,
                            images: notePage.imageStack)
                    selectionPaths =
                        LassoToolHelper.createSelectionBounds(
                            imageStack: notePage.imageStack,
                            selectedLines: selectedLineStack,
                            selectedImages: selectedImageObjIds)
                }
            case .laser:  // Laser Mode
              
               
                laserTimerManager.setLaserTimer(onFadout: {
                    if(lastDrawLaserPosition == nil) {
                        fadeOutLasers()
                    }
                })

                
            }
        } else {
            print("Invalid mode selected.")
        }
    }
    
    private func fadeOutLasers() {
        laserOpacity = 1;
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            laserOpacity -= 0.3

            if laserOpacity <= 0 {
                laserOpacity = 1.0;
                timer.invalidate()
                laserStack = [] // Clear the stack when all lasers have faded
            }
        }
    }


    private func findCurrentDrawingLine() -> LineObj? {
        guard let drawingLineID = currentDrawingLineID else {
            return nil
        }
        return notePage.lineStack.first(where: { $0.id == drawingLineID })
    }

    private func handleDrawing(dragValue: DragGesture.Value) {
        if lastDrawPosition == nil {
            // Start a new stroke when drag begins
            print("First drag detected for a new stroke")
            let newLine = LineObj(
                color: canvasState.penColor,
                points: [dragValue.location],
                lineWidth: canvasState.penSize,
                mode: .draw
            )
            notePage.lineStack.append(newLine)  // Add a new line
            currentDrawingLineID = newLine.id
        } else {
            // Add points to the current stroke
            print("drag detected for a new stroke2")
            if let lastLine = notePage.lineStack.last {
                let interpolatedPoints = PointHelper.interpolatePoints(
                    from: lastLine.points.last ?? dragValue.location,
                    to: dragValue.location
                )
                let lastIndex: Int = notePage.lineStack.count - 1
                notePage.lineStack[lastIndex].points.append(
                    contentsOf: interpolatedPoints)
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

    private func processLineForTransformation(_ line: LineObj) {
        guard
            let index = notePage.lineStack.firstIndex(where: {
                $0.id == line.id
            })
        else {
            print(
                "Line with id \(line.id) not found. No transformation applied.")
            return
        }

        let shapePoints = ShapeHelper.lineToShape(line)
        if !shapePoints.isEmpty {
            notePage.lineStack[index].points = shapePoints
            lastDrawPosition = nil
        }
    }

    private func handleErasing(dragValue: DragGesture.Value) {
        notePage.lineStack = EraseHelper.eraseLines(
            lines: notePage.lineStack, dragValue: dragValue,
            eraserRadius: canvasState.penSize)
    }

    private func handleSelection(dragValue: DragGesture.Value) {
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
                    imageStack: notePage.imageStack,
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
                for i in 0..<notePage.imageStack.count {
                    if selectedImageObjIds.contains(
                        notePage.imageStack[i].id)
                    {
                        notePage.imageStack[i].position.x +=
                            centerTranslation.width
                        notePage.imageStack[i].position.y +=
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
                    if let index = notePage.lineStack.firstIndex(where: {
                        $0.id == selectedLine.id
                    }) {
                        notePage.lineStack[index] = selectedLine
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
