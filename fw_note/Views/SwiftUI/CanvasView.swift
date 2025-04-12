//
//  CanvasView.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import PDFKit
import SwiftUI

struct CanvasView: View {
    let pageIndex: Int
    var onGesture: ((CGFloat, CGSize) -> Void)?
    @ObservedObject var imageState: ImageState
  
    @ObservedObject var canvasState: CanvasState
    @ObservedObject var noteFile: NoteFile
    @ObservedObject var noteUndoManager: NoteUndoManager
    @ObservedObject var notePage: NotePage

    //Selected
    @State var selectionPaths: [CGPoint] = []
    @State var selectedImageObjIds: [UUID] = []
    @State var selectedGifObjIds: [UUID] = []
    @State var selectedLineStack: [LineObj] = []

    //Laser
    @State var laserStack: [LineObj] = []
    @State var laserOpacity: Double = 1.0
    @State var laserTimerManager = LaserTimerManager()
    @State var lastDrawLaserPosition: CGPoint? = nil

    //Control
    @State var isTouching: Bool = false
    @State var isLaserCreated: Bool = false
    @State var isLassoCreated: Bool = false
    @State var redrawTrigger: Bool = false
    @State var isTapImage: Bool = false
    @State private var isDraggingOver: Bool = false
    @State private var isDraggingOutsize: Bool = false

    @State var focusedID: UUID?
    @State var currentDrawingLineID: UUID? = nil
    @State var touchPoint: CGPoint? = nil
    @State var lastDrawPosition: CGPoint? = nil
    @State var lastDragPosition: CGPoint? = nil

    @State var imageStack: [ImageObj] = []
    @State private var pageSize: CGSize = .zero
    let onDoubleTap: () -> Void
    //@Binding var shouldScroll: Bool
    private var axes: Axis.Set {
        //return shouldScroll ? .horizontal : []
        return []
    }

    var canvas: some View {
      
            ScrollView(axes, showsIndicators: false) {
             
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
                                            y: imageObj.position.y
                                        )
                                        let radians =
                                            CGFloat(imageObj.angle) * .pi / 180
                                        cgContext.rotate(by: radians)
                                        cgContext.scaleBy(x: 1.0, y: -1.0)

                                        cgContext.draw(
                                            cgImage,
                                            in: CGRect(
                                                origin: CGPoint(
                                                    x: -imageObj.size.width / 2,
                                                    y: -imageObj.size.height / 2
                                                ),
                                                size: imageObj.size
                                            )
                                        )

                                        cgContext.restoreGState()
                                    }
                                }
                            }

                            // Handle LineObj
                            if let line = canvasObj.lineObj {
                                let path = PathHelper.createStableCurvedPath(
                                    points: line.points,
                                    maxOffsetForAverage: 4.5
                                )
                                if selectedLineStack.contains(where: {
                                    $0.id == line.id
                                }) {
                                    context.stroke(
                                        path,
                                        with: .color(.blue),
                                        style: StrokeStyle(
                                            lineWidth: line.lineWidth
                                        )
                                    )
                                } else {
                                    if line.mode == .draw {
                                        context.blendMode = .normal
                                        context.stroke(
                                            path,
                                            with: .color(line.color),
                                            style: StrokeStyle(
                                                lineWidth: line.lineWidth,
                                                lineCap: .round,
                                                lineJoin: .round
                                            )
                                        )
                                        context.blendMode = .normal

                                    } else if line.mode == .eraser {
                                        context.blendMode = .clear
                                        context.stroke(
                                            path,
                                            with: .color(line.color),
                                            style: StrokeStyle(
                                                lineWidth: line.lineWidth,
                                                lineCap: .round,
                                                lineJoin: .round
                                            )
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
                                selectionPaths
                            )
                            selectionDrawing.closeSubpath()
                            context.stroke(
                                selectionDrawing,
                                with: .color(.green),
                                style: StrokeStyle(lineWidth: 2, dash: [5, 5])
                            )
                        }
                        
                        for laser in laserStack {
                            // Create the path for the laser points
                            var path = PathHelper.createStableCurvedPath(
                                points: laser.points,
                                maxOffsetForAverage: 4.5
                            )

                            // Smooth the path (if needed)
                            path = path.strokedPath(
                                StrokeStyle(
                                    lineWidth: 1,
                                    lineCap: .round,
                                    lineJoin: .round
                                )
                            )

                            // Simulate the blur effect by layering strokes with varying opacities and line widths
                            let blurLevels = [
                                (opacity: 0.1, lineWidth: 15),
                                (opacity: 0.2, lineWidth: 12),
                                (opacity: 0.4, lineWidth: 9),
                                (opacity: 0.6, lineWidth: 6),
                            ]

                            for blur in blurLevels {
                                context.stroke(
                                    path,
                                    with: .color(
                                        Color.red.opacity(
                                            laserOpacity > blur.opacity
                                                ? blur.opacity : laserOpacity
                                        )
                                    ),  // Fading outwards
                                    style: StrokeStyle(
                                        lineWidth: CGFloat(blur.lineWidth),
                                        lineCap: .round,
                                        lineJoin: .round
                                    )
                                )
                            }

                            // Render the core white laser beam
                            context.stroke(
                                path,
                                with: .color(.white.opacity(laserOpacity)),
                                style: StrokeStyle(
                                    lineWidth: 3,
                                    lineCap: .round,
                                    lineJoin: .round
                                )
                            )
                        }

                    }
                    .drawingGroup()
                    /* .simultaneousGesture(
                         gestureState.areGesturesEnabled
                             ? DragGesture(minimumDistance: 0)  // Handles both taps and drags
                                 .onChanged { value in
                                     focusedID = nil
                                     print("touch1")
                                     if value.translation == .zero {
                                         print("touch1a")
                                         // Handle as a tap gesture
                                         handleTap(at: value.startLocation)
                                     } else {
                                         print("touch1b")
                    
                                         let customValue: CustomDragValue =
                                             CustomDragValue(
                                                 time: value.time,
                                                 location: value.location,
                                                 startLocation: value
                                                     .startLocation,
                                                 translation: value
                                                     .translation,
                                                 predictedEndTranslation:
                                                     value
                                                     .predictedEndTranslation,
                                                 predictedEndLocation: value
                                                     .predictedEndLocation
                                             )
                                         // Handle as a drag gesture
                                         handleDragChange(
                                             dragValue: customValue
                                         )
                                     }
                    
                                     //  handleDragChange(dragValue: value)
                                 }
                                 .onEnded { value in
                                     print("onDrag ended")
                                     handleDragEnded()  // Finalize drag action
                                 } : nil
                     )*/

        }
    }

    var body: some View {
        VStack {
            /* Button("Save") {
                 guard let relativePath = noteFile.pdfFilePath else {
                     print("Error: PDF file path is nil")
                     return
                 }
            
                 let pdfFileUrl = FileHelper.getAbsoluteProjectPath(
                     userId: "guest",
                     relativePath: relativePath
                 )
                 guard let pdfFileUrl = pdfFileUrl else {
                     print("Error: Could not get absolute project path")
                     return
                 }
            
                 print("Press \(pdfFileUrl)")
                 guard let pdfDocument = PDFDocument(url: pdfFileUrl) else {
                     print("Error opening PDF file")
                     return
                 }
            
                 guard
                     let page = pdfDocument.page(
                         at: canvasState.currentPageIndex
                     )
                 else {
                     print(
                         "Error: Could not get page at index \(canvasState.currentPageIndex)"
                     )
                     return
                 }
            
                 let canvasSnapshot = canvas.frame(
                     width: pageSize.width,
                     height: pageSize.height
                 ).snapshot()
                 let pdfImage = page.thumbnail(of: pageSize, for: .mediaBox)
            
                 guard
                     let combinedImage = combineImages(
                         baseImage: pdfImage,
                         overlayImage: canvasSnapshot
                     )
                 else {
                     print("Error combining images")
                     return
                 }
            
                 UIImageWriteToSavedPhotosAlbum(combinedImage, nil, nil, nil)
             }*/

            /* HStack {
                Text("init: \(noteUndoManager.initCanvasStack.count)")
                Text("Undo: \(noteUndoManager.undoStack.count)")
                Text("Redo: \(noteUndoManager.redoStack.count)")
                Text("currentIndex: \(canvasState.currentPageIndex)")
            }*/

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

                    canvas
                    // .border(.red, width: 1)
                      .onAppear {
                            currentProjectId = noteFile.id
                            pageSize = geometry.size
                            redrawTrigger.toggle()
                            notePage.pageCenterPoint = CGPoint(
                                x: geometry.size.width / 2,
                                y: geometry.size.height / 2
                            )
                            notePage.canvasWidth = geometry.size.width
                            notePage.canvasHeight = geometry.size.height
                            imageStack = notePage.canvasStack.compactMap {
                                $0.imageObj
                            }
                            focusedID = nil
                            isDraggingOver = false
                            exportSnapShot()
                        }
                        .allowsHitTesting(false)  // Toggle interaction
                       
                    // Pencil Detection View as overlay
                   PencilDetectionView(
                        onTap: { value in
                           
                            focusedID = nil
                            handleTap(
                                at: value.startLocation,
                                noteFile: noteFile
                            )
                        },
                        onTouchBegin: { value in
                            focusedID = nil
                           
                            if value.type == .pencil {
                                print("touch with pencil")
                            } else {
                                print("touch with fingers")
                            }
                            
                            handleDragBegin(
                                dragValue: value
                            )
                        },
                        onTouchMove: { value in
                           handleDragChange(
                                dragValue: value,
                                callback: {}
                            )
                        },
                        onTouchEnd: { value in
                          handleDragChange(
                                dragValue: value,
                                callback: {
                                    handleDragEnded()
                                }
                            )
                        },
                        onTouchCancel: {
                           handleDragEnded()
                        }

                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.clear)
                   
                 
                        ForEach($imageStack) { imageObj in
                            InteractiveImageView(
                                imageObj: imageObj,
                                selectMode: .constant(
                                    canvasState.canvasMode != CanvasMode.lasso
                                ),  // Avoid binding if it's derived
                                isFocused: .constant(focusedID == imageObj.id),
                                frameSize: geometry.size,
                                onTap: onTapImage,
                                onRemove: onRemoveImage,
                                onChanged: onChangeImage,
                                afterChanged: afterChangeImage
                            )
                        }.clipped()
                 
                }
                .onDrop(
                    of: ["public.image", "com.compuserve.gif"],
                    isTargeted: $isDraggingOver
                ) { providers in
                    print("providers")
                    return handleDrop(providers: providers)
                }

                if isDraggingOver {
                    DropZoneView(isDraggingOver: $isDraggingOver)
                }
              
            }
            .onTapGesture {
                isDraggingOver = false

            }
            .gesture(
                TapGesture(count: 2)  // Double-tap gesture
                    .onEnded {
                        onDoubleTap()  // Trigger the closure when double-tap is detected
                    }
            )
            .onChange(of: canvasState.canvasMode) {
                newMode in
                handleModeChange(mode: newMode)
            }
            .onChange(of: notePage.canvasStack) { newStack in
                imageStack = newStack.compactMap { $0.imageObj }
                focusedID = nil
                isDraggingOver = false
                exportSnapShot()
            }
            .onAppear {
                canvasState.canvasPool[pageIndex] = AnyView(canvas)
                noteUndoManager.addInitialCanvasStack(
                    pageIndex: pageIndex,
                    canvasStack: self.notePage.canvasStack.last
                        ?? CanvasObj(id: UUID(), lineObj: nil, imageObj: nil)
                )
            }

        }
    }

    func createPDFPage(with image: UIImage, size: CGSize) -> PDFPage? {
        let pdfPageRect = CGRect(origin: .zero, size: size)
        let mutableData = NSMutableData()  // Create NSMutableData for the PDF context
        UIGraphicsBeginPDFContextToData(mutableData, pdfPageRect, nil)
        UIGraphicsBeginPDFPageWithInfo(pdfPageRect, nil)

        // Draw the combined image in the PDF context
        image.draw(in: pdfPageRect)

        UIGraphicsEndPDFContext()  // End the PDF context

        // Use the data to create a PDFDocument and extract the page
        guard let pdfData = mutableData as Data? else { return nil }
        return PDFDocument(data: pdfData)?.page(at: 0)
    }

    func combineImages(baseImage: UIImage, overlayImage: UIImage) -> UIImage? {
        let size = baseImage.size  // Use the size of the base image
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)

        // Draw the base image
        baseImage.draw(in: CGRect(origin: .zero, size: size))

        // Draw the overlay image on top
        overlayImage.draw(in: CGRect(origin: .zero, size: size))

        // Generate the combined image
        let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return combinedImage
    }

    func onTapImage(id: UUID) {
        focusedID = id
    }

    func onRemoveImage(id: UUID) {
        // Find the index of the image object to be removed
        if let index = notePage.canvasStack.firstIndex(where: {
            $0.imageObj?.id == id
        }) {
            guard let pathToRemove = notePage.canvasStack[index].imageObj?.path
            else {
                print("Path not found for the image object")
                return
            }

            // Check if any other image objects contain the same path
            let isUniquePath = !notePage.canvasStack.contains(where: {
                $0.imageObj?.path == pathToRemove && $0.imageObj?.id != id
            })

            // If this path is unique (only one image object has it), remove the file
            if isUniquePath {
                removeFile(at: pathToRemove)
            }

            // Remove the image object from the canvas stack
            notePage.canvasStack.remove(at: index)

            // Add the current state of the canvas stack to the undo manager
            noteUndoManager.addToUndo(
                pageIndex: pageIndex,
                canvasStack: notePage.canvasStack
            )
        }
    }

    private func removeFile(at path: String) {
        do {
            guard
                let absolutePath = FileHelper.getProjectImageFilePath(
                    imageName: path,
                    projectId: currentProjectId!
                )
            else {
                print("Error: absolutePath is nil")
                return
            }

            try FileManager.default.removeItem(atPath: absolutePath)
            print("File removed at path: \(absolutePath)")
        } catch {
            print("Failed to remove file at path: \(path), error: \(error)")
        }
    }

    func onChangeImage(id: UUID, imageObj: ImageObj) {
        if let index = notePage.canvasStack.firstIndex(
            where: { $0.imageObj?.id == id })
        {
            notePage.canvasStack[index].imageObj = imageObj
        }
    }

    func afterChangeImage(id: UUID, imageObj: ImageObj) {

        if let index = notePage.canvasStack.firstIndex(
            where: { $0.imageObj?.id == id })
        {
            print("imageObj - \(imageObj.size)")
            notePage.canvasStack[index].imageObj = imageObj

            noteUndoManager.addToUndo(
                pageIndex: self.pageIndex,
                canvasStack: notePage.canvasStack
            )
            exportSnapShot()
        }

    }

    // Modularized Tap Handling Function
    private func handleTap(at location: CGPoint, noteFile: NoteFile?) {
        // Perform hit-testing for images in canvasStack
        for canvasObj in notePage.canvasStack.reversed() {
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
                    isTapImage = true
                    return
                }
            }
        }

    }

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
    
    private func handleDragBegin(dragValue: TouchData) {
        self.isTouching = true
        self.isTapImage = false
        self.touchPoint = dragValue.location

        switch canvasState.canvasMode {
        case .draw:  // Draw Mode
            handleBeginDrawing(dragValue: dragValue)
        case .eraser:  // Erase Mode
            break
        case .lasso:  // Select Mode
            break
        case .laser:  // Laser Mode
            break
        }
    }

    private func handleDragChange(dragValue: TouchData, callback: (() -> Void)?) {
        self.isTouching = true
        self.isTapImage = false
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
        
        callback?()
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
            if self.isTapImage == false {
                noteUndoManager.addToUndo(
                    pageIndex: pageIndex,
                    canvasStack: self.notePage.canvasStack
                )

            } else {
                self.isTapImage = false
            }
        case .eraser:  // Erase Mode
            lastDragPosition = nil
            noteUndoManager.addToUndo(
                pageIndex: pageIndex,
                canvasStack: self.notePage.canvasStack
            )
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
                        lines: lineStack
                    )
                selectedImageObjIds =
                    LassoToolHelper.getSelectedImages(
                        selectionPath: selectionPaths,
                        images: imageStack
                    )
                selectionPaths =
                    LassoToolHelper.createSelectionBounds(
                        imageStack: imageStack,
                        selectedLines: selectedLineStack,
                        selectedImages: selectedImageObjIds
                    )
            }
        case .laser:  // Laser Mode

            laserTimerManager.setLaserTimer(onFadout: {

                if lastDrawLaserPosition == nil {
                    fadeOutLasers()
                }
            })
        }

        exportSnapShot()
    }

    private func fadeOutLasers() {
        laserOpacity = 1
        isLaserCreated = false
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if self.isLaserCreated == false {
                self.laserOpacity -= 0.3

                if laserOpacity <= 0 {
                    laserOpacity = 1.0
                    timer.invalidate()
                    laserStack = []  // Clear the stack when all lasers have faded
                }
            } else {
                self.laserOpacity = 1
                timer.invalidate()
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
    
    private func handleBeginDrawing(dragValue: TouchData) {
        print("changed pageIndex: \(pageIndex)")
        canvasState.setPageIndex(pageIndex)
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
    }

    private func handleDrawing(dragValue: TouchData) {
        
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
                        contentsOf: interpolatedPoints
                    )
                }
          
        }

        // Update hold detection logic for the latest position
        if lastDrawPosition != nil {
            if PointHelper.distance(
                lastDrawPosition!,
                dragValue.location
            ) > 5.0 {
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
                "LineObj at index \(index) is nil. No transformation applied."
            )
            return
        }

        let shapePoints = ShapeHelper.lineToShape(currentLineObj)
        print("shapePoints \(shapePoints)")
        if !shapePoints.isEmpty {
            // Update the points of the lineObj in the canvasStack
            print("changed")

            notePage.canvasStack[index].lineObj?.points.removeAll()
            notePage.canvasStack[index].lineObj?.points.append(
                contentsOf: shapePoints
            )

            self.lastDrawPosition = nil  // Reset the last draw position
            redrawTrigger.toggle()
        }
    }

    private func handleLaser(dragValue: TouchData) {
        isLaserCreated = true
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
                    contentsOf: interpolatedPoints
                )
            }
        }
        lastDrawLaserPosition = dragValue.location
    }

    private func handleErasing(dragValue: TouchData) {
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

    private func handleSelection(dragValue: TouchData) {
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
            point: dragValue.location
        )

        if isCurrentlyInsideSelection {
            print("Dragging inside selection")
            if hasSelectedItems {

                let centerTranslation = LassoToolHelper.getCenterTranslation(
                    dragValue: dragValue,
                    imageStack: imageStack,
                    selectedLines: selectedLineStack,
                    selectedImages: selectedImageObjIds
                )

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

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            print("Checking provider...")

            // Check if the provider has an item conforming to "public.image"
            if provider.hasItemConformingToTypeIdentifier("public.image") {
                canvasState.isDragging = true
                isDraggingOver = false
                if provider.registeredTypeIdentifiers.contains(
                    "com.compuserve.gif"
                ) {
                    print("Detected GIF")

                    // Load the GIF using its type identifier
                    provider.loadItem(
                        forTypeIdentifier: "com.compuserve.gif",
                        options: nil
                    ) { item, error in
                        if let data = item as? Data {
                            // Successfully loaded the GIF data
                            print(
                                "Successfully loaded GIF data: \(data.count) bytes"
                            )

                            if let originalImageObj =
                                imageState.saveImageFromData(data, isGif: true)
                            {
                                addImageToStack(image: originalImageObj)
                            }
                        } else if let url = item as? URL {
                            print("GIF URL received: \(url)")
                            ImageHelper.handleGIFWithUUID(
                                input: url.path,
                                completion: { savedPath in
                                    if let path = savedPath {
                                        if let originalImageObj =
                                            imageState.saveImage(filePath: path)
                                        {
                                            addImageToStack(
                                                image: originalImageObj
                                            )
                                        }
                                    } else {
                                        print("Failed to save GIF.")
                                    }
                                }
                            )
                        } else {
                            print(
                                "Failed to load GIF: \(String(describing: error))"
                            )
                        }
                    }

                } else {
                    // Handle non-GIF image formats
                    provider.loadObject(ofClass: UIImage.self) { item, error in
                        guard error == nil, let uiImage = item as? UIImage
                        else {
                            print(
                                "Failed to load image: \(String(describing: error))"
                            )
                            return
                        }

                        if let imageData = uiImage.pngData() {
                            // Use the `imageData` as needed (e.g., save to file or upload)
                            print(
                                "Image successfully converted to PNG data. Size: \(imageData.count) bytes."
                            )
                            if let originalImageObj =
                                imageState.saveImageFromData(
                                    imageData,
                                    isGif: false
                                )
                            {
                                addImageToStack(image: originalImageObj)
                            }

                        } else {
                            print("Failed to convert UIImage to PNG data.")

                        }

                    }
                }
            }
            return true  // Successfully handled provider
        }
        isDraggingOver = false
        return false  // No valid providers were processed
    }

    private func addImageToStack(image: OriginalImageObj) {
        // Calculate base position
        let pageIndex = canvasState.currentPageIndex
        let basePosition = notePage.pageCenterPoint
        let newPosition = CGPoint(x: basePosition.x, y: basePosition.y)

        // Create the ImageObj with the filtered and adjusted position
        let newImageObj = ImageObj(
            path: image.absolutePath,
            position: newPosition,
            size: image.size
        )

        // Create a new CanvasObj containing the ImageObj
        let newCanvasObj = CanvasObj(lineObj: nil, imageObj: newImageObj)

        // Add the new CanvasObj to the canvas stack
        notePage.canvasStack.append(
            newCanvasObj
        )

        // Add the operation to the undo stack
        noteUndoManager.addToUndo(
            pageIndex: pageIndex,
            canvasStack: notePage.canvasStack
        )
    }

    func exportSnapShot() {
        /* guard let relativePath = noteFile.pdfFilePath else {
             print("Error: PDF file path is nil")
             return
         }
        
         let pdfFileUrl = FileHelper.getAbsoluteProjectPath(
             userId: "guest",
             relativePath: relativePath
         )
         guard let pdfFileUrl = pdfFileUrl else {
             print("Error: Could not get absolute project path")
             return
         }
        
         print("Press \(pdfFileUrl)")
         guard let pdfDocument = PDFDocument(url: pdfFileUrl) else {
             print("Error opening PDF file")
             return
         }
        
         guard
             let page = pdfDocument.page(
                 at: canvasState.currentPageIndex
             )
         else {
             print(
                 "Error: Could not get page at index \(canvasState.currentPageIndex)"
             )
             return
         }
        
         let canvasSnapshot = canvas.frame(
             width: pageSize.width,
             height: pageSize.height
         ).snapshot()
         let pdfImage = page.thumbnail(of: pageSize, for: .mediaBox)
        
        
         let imageName = "drawing_\(pageIndex).png"  // Start index from 1 for readability
        
         guard
             let noteThumbnailDirectory = FileHelper.getNoteThumbnailDirectory(
                 userId: "guest",
                 noteId: noteFile.id.uuidString
             )
         else {
             print("Error get note thumbnail directory")
             return
         }
         do {
             let imageURL = noteThumbnailDirectory.appendingPathComponent(imageName)
             try canvasSnapshot.pngData()?.write(to: imageURL)
             print("image saved successfully to \(imageURL)")
         } catch {
             print("image saved error \(error)")
         }
        */
    }

}
