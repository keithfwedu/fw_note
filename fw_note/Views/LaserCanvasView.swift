//
//  MainView.swift
//  pdf_note
//
//  Created by Fung Wing on 7/3/2025.
//

import SwiftUI
import PencilKit

struct LaserCanvasView: UIViewRepresentable {
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: LaserCanvasView
        private var timer: Timer?
        private var fadeOutTimer: Timer?

        init(parent: LaserCanvasView) {
            self.parent = parent
        }
        
        func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
            print("start");
            invalidateTimer()
        }

       
       func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            print("end");
            startTimer(for: canvasView)
    }

        func startTimer(for canvasView: PKCanvasView) {
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                print("Clearing canvas")
                //canvasView.drawing = PKDrawing() // Clear the drawing
                self.clearDrawingWithFade(for: canvasView);
            }
        }

        private func invalidateTimer() {
            timer?.invalidate() // Stop the existing timer if it's running
            timer = nil
        }
        
        func clearDrawingWithFade(for canvasView: PKCanvasView) {
            fadeOutTimer?.invalidate() // Stop any existing fade-out process
                       fadeOutTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                           var updatedStrokes: [PKStroke] = []
                           
                           for stroke in canvasView.drawing.strokes {
                               // Reduce opacity by modifying the stroke's color
                               let newColor = stroke.ink.color.withAlphaComponent(stroke.ink.color.cgColor.alpha - 0.5)
                               if newColor.cgColor.alpha > 0 {
                                   let newInk = PKInk(stroke.ink.inkType, color: newColor)
                                   updatedStrokes.append(PKStroke(ink: newInk, path: stroke.path))
                               }
                           }

                           if updatedStrokes.isEmpty {
                               // Stop the timer and clear the canvas when all strokes fade out
                               timer.invalidate()
                               canvasView.drawing = PKDrawing() // Clear the canvas
                           } else {
                               // Update the canvas with the faded strokes
                               canvasView.drawing = PKDrawing(strokes: updatedStrokes)
                           }
                       }
                }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = UIColor.clear // Transparent background
        
        // Set the tool to use white color for drawing
        let inkingTool = PKInkingTool(.pen, color: UIColor.white, width: 5)
        canvasView.tool = inkingTool
        canvasView.layer.shadowColor = UIColor.red.cgColor
        canvasView.layer.shadowRadius = 3
        canvasView.layer.shadowOpacity = 1.0
        canvasView.layer.shadowOffset = CGSize(width: 0, height: 0)
          
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // No updates needed at the moment
    }
}
