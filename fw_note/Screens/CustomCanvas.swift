//
//  CustomCanvas.swift
//  fw_note
//
//  Created by Alex Ng on 20/3/2025.
//

import SwiftUI
import PDFKit

import UIKit

/*class CustomCanvas: UIView {
    let pageIndex: Int

    var canvasState: CanvasState
    var notePage: NotePage

    init(frame: CGRect, pageIndex: Int, canvasState: CanvasState, notePage: NotePage) {
        self.pageIndex = pageIndex
        self.canvasState = canvasState
        self.notePage = notePage
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let context = UIGraphicsGetCurrentContext()

        // Draw dynamic touch circle
        if let touchPoint = canvasState.touchPoint, canvasState.isTouching {
            context?.setStrokeColor(UIColor.gray.cgColor)
            context?.setLineWidth(0.5)
            let circleRect = CGRect(x: touchPoint.x - 6.5, y: touchPoint.y - 6.5, width: 13, height: 13)
            context?.strokeEllipse(in: circleRect)
        }

        // Draw image objects
        for image in notePage.imageObjs {
            let rectPath = UIBezierPath(rect: image.rect)
            UIColor.gray.setFill()
            rectPath.fill()

            // Highlight selected images
            if canvasState.selectedImageObjIds.contains(image.id) {
                let selectionRect = image.rect.insetBy(dx: -2, dy: -2)
                let borderPath = UIBezierPath(rect: selectionRect)
                UIColor.blue.setStroke()
                context?.setLineWidth(2)
                borderPath.stroke()
            }
        }

        // Draw lines
        for line in notePage.lineObjs {
            let path = UIBezierPath()
            path.move(to: line.points.first ?? CGPoint.zero)
            for point in line.points.dropFirst() {
                path.addLine(to: point)
            }

            if canvasState.selectedLineObjs.contains(where: { $0.id == line.id }) {
                UIColor.blue.setStroke()
                context?.setLineWidth(8)
                path.stroke()
            } else {
                switch line.mode {
                case .draw:
                    context?.setBlendMode(.normal)
                    context?.setStrokeColor(line.color.cgColor ?? UIColor.red.cgColor)
                    context?.setLineWidth(8)
                    path.stroke()
                case .eraser:
                    context?.setBlendMode(.clear)
                    context?.setStrokeColor(UIColor.clear.cgColor)
                    context?.setLineWidth(8)
                    path.stroke()
                case .lasso:
                    print("lasso")
                case .laser:
                    print("laser")
                }
            }
        }

        // Draw lasso selection path
        if CanvasMode(rawValue: canvasState.selectionModeIndex) == .lasso && !canvasState.selectionPath.isEmpty {
            let selectionPath = UIBezierPath()
            selectionPath.move(to: canvasState.selectionPath.first ?? CGPoint.zero)
            for point in canvasState.selectionPath.dropFirst() {
                selectionPath.addLine(to: point)
            }
            selectionPath.close()
            context?.setStrokeColor(UIColor.green.cgColor)
            context?.setLineWidth(2)
            context?.setLineDash(phase: 0, lengths: [5, 5])
            selectionPath.stroke()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchPoint = touch.location(in: self)
        canvasState.touchPoint = touch.location(in: self)
        canvasState.isTouching = true
        setNeedsDisplay()
        if let mode = CanvasMode(rawValue: canvasState.selectionModeIndex) {
            switch mode {
            case .draw:
                handleDrawing(touchPoint)
            case .eraser:
                handleErasing(touchPoint)
            case .lasso:
                handleSelection(touchPoint)
            case .laser:
                print("Laser Mode - touches began")
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        canvasState.touchPoint = touch.location(in: self)
        let touchPoint = touch.location(in: self)

        if let mode = CanvasMode(rawValue: canvasState.selectionModeIndex) {
            switch mode {
            case .draw:
                handleDrawing(touchPoint)
            case .eraser:
                handleErasing(touchPoint)
            case .lasso:
                handleSelection(touchPoint)
            case .laser:
                print("Laser Mode - touches moved")
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleDragEnded()
        canvasState.isTouching = false
        setNeedsDisplay()
    }




    private func handleDragEnded() {
        print("Erase Mode Gesture Ended")
        canvasState.lastDrawPosition = nil
        canvasState.isTouching = false

        if let mode = CanvasMode(rawValue: canvasState.selectionModeIndex) {
            switch mode {
            case .draw:
                canvasState.lastDragPosition = nil
                canvasState.timerManager.cancelHoldTimer()

            case .eraser:
                canvasState.lastDragPosition = nil

            case .lasso:
                if !canvasState.selectionPath.isEmpty && !canvasState.isLassoCreated {
                    let hasSelectedItems = !canvasState.selectedLineObjs.isEmpty || !canvasState.selectedImageObjIds.isEmpty
                    canvasState.isLassoCreated = hasSelectedItems
                    canvasState.selectedLineObjs = LassoToolHelper.getSelectedLines(
                        selectionPath: canvasState.selectionPath,
                        lines: notePage.lineObjs
                    )
                    canvasState.selectedImageObjIds = LassoToolHelper.getSelectedImages(
                        selectionPath: canvasState.selectionPath,
                        images: notePage.imageObjs
                    )
                    canvasState.selectionPath = LassoToolHelper.createSelectionBounds(
                        imageObjs: notePage.imageObjs,
                        selectedLines: canvasState.selectedLineObjs,
                        selectedImages: canvasState.selectedImageObjIds
                    )
                }
            case .laser:
                print("Laser Mode")
            }
        } else {
            print("Invalid mode selected.")
        }
    }

    private func handleDrawing(_ dragValue: CGPoint) {
        if canvasState.lastDrawPosition == nil {
            let newLine = LineObj(
                color: .brown,
                points: [dragValue],
                mode: .draw
            )
            notePage.lineObjs.append(newLine)
            canvasState.currentDrawingLineID = newLine.id
        } else {
            if let lastLine = notePage.lineObjs.last {
                let interpolatedPoints = PointHelper.interpolatePoints(
                    from: lastLine.points.last ?? dragValue,
                    to: dragValue
                )
                let lastIndex = notePage.lineObjs.count - 1
                notePage.lineObjs[lastIndex].points.append(contentsOf: interpolatedPoints)
            }
        }

        canvasState.lastDrawPosition = dragValue
    }

    private func handleErasing(_ touchPoint: CGPoint) {
        // Update `notePage.lineObjs` by erasing lines intersecting the given point
        notePage.lineObjs = EraseHelper.eraseLines(lines: notePage.lineObjs, touchPoint: touchPoint)
        setNeedsDisplay() // Redraw the canvas to reflect the changes
    }

    private func handleSelection(_ touchPoint: CGPoint) {
        // Check if there are already selected items
        let hasSelectedItems = !canvasState.selectedLineObjs.isEmpty || !canvasState.selectedImageObjIds.isEmpty

        // If this is the first touch for selection, initialize the selection path
        if canvasState.lastDragPosition == nil {
            print("First touch detected for selection")
            resetSelection()
            canvasState.selectionPath = [touchPoint]
            canvasState.lastDragPosition = touchPoint
            setNeedsDisplay() // Redraw the canvas to reflect changes
            return
        }

        // Check if the current touch point is inside the existing selection area
        if LassoToolHelper.isPointInsideSelection(canvasState.selectionPath, point: touchPoint) {
            print("Touching inside selection")
            if hasSelectedItems {
                // Calculate the translation for moving selected items
                let translation = LassoToolHelper.getCenterTranslation(
                    touchPoint: touchPoint,
                    imageObjs: notePage.imageObjs,
                    selectedLines: canvasState.selectedLineObjs,
                    selectedImages: canvasState.selectedImageObjIds
                )

                // Move selected lines
                for i in 0..<canvasState.selectedLineObjs.count {
                    canvasState.selectedLineObjs[i].points = canvasState.selectedLineObjs[i].points.map {
                        CGPoint(x: $0.x + translation.width, y: $0.y + translation.height)
                    }
                }

                // Move selected images
                for i in 0..<notePage.imageObjs.count {
                    if canvasState.selectedImageObjIds.contains(notePage.imageObjs[i].id) {
                        notePage.imageObjs[i].position.x += translation.width
                        notePage.imageObjs[i].position.y += translation.height
                    }
                }

                // Update the selection path to reflect the move
                canvasState.selectionPath = LassoToolHelper.moveSelectionPath(
                    selectionPath: canvasState.selectionPath,
                    translation: translation
                )
            }
        } else {
            // If touch is outside the selection area, reset or extend the selection
            print("Touching outside selection")
            if hasSelectedItems {
                resetSelection()
                canvasState.isLassoCreated = false
            }

            if !canvasState.isLassoCreated {
                canvasState.selectionPath.append(touchPoint)
            }
        }

        // Update the last touch position
        canvasState.lastDragPosition = touchPoint
        setNeedsDisplay() // Redraw the canvas to reflect changes
    }

    private func resetSelection() {
        canvasState.selectedLineObjs.removeAll()
        canvasState.selectedImageObjIds.removeAll()
        canvasState.selectionPath.removeAll()
        canvasState.isLassoCreated = false
    }
}
*/

import SwiftUI
import UIKit

class CustomCanvas: UIView {

        private var hostingController: UIHostingController<CanvasView>?

        init(frame: CGRect, pageIndex: Int, canvasState: CanvasState, notePage: NotePage) {
            super.init(frame: frame)
            
            // Create the SwiftUI `CanvasView` with the necessary properties
            let canvasView = CanvasView(pageIndex: pageIndex, canvasState: canvasState, notePage: notePage)
            
            // Embed the SwiftUI `CanvasView` in a `UIHostingController`
            let hostingController = UIHostingController(rootView: canvasView)
            self.hostingController = hostingController
            
            // Add the hosting controller's view as a child of this wrapper
            if let hostingView = hostingController.view {
                hostingView.frame = self.bounds
                hostingView.backgroundColor = .clear // Ensure transparent background
                hostingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                self.addSubview(hostingView)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            // Ensure the hosting controller's view matches the size of the wrapper
            hostingController?.view.frame = self.bounds
        }
    }
