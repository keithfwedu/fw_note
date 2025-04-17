//
//  CanvasState.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import CoreData
import PDFKit
import PencilKit
import SwiftUI

class CanvasState: ObservableObject {
    private var isInitialized = false
    
    @Published var isEdited: Bool = false
    //PDF State
    @Published var currentPageIndex: Int = 0
    @Published var currentProjectId: String? = nil

    //State
    @Published var timerManager = TimerManager()
    @Published var canvasMode: CanvasMode = CanvasMode.draw
    @Published var canvasTool: CanvasTool = CanvasTool.pen
    @Published var eraseMode: EraseMode = EraseMode.rubber

    @Published var showImagePicker: Bool = false
    @Published var isDragging: Bool = false

    @Published var canvasPool: [Int: AnyView] = [:]
 
    
    //Configs
    @Published var displayDirection: PDFDisplayDirection = .vertical {
        didSet {
            if isInitialized {
                updatePdfState()
            }
        }
    }
    @Published var penSize: CGFloat = 0.5 {
        didSet {
            if isInitialized {
                updatePdfState()
            }
        }
    }
    @Published var penColor: Color = .black {
        didSet {
            if isInitialized {
                updatePdfState()
            }
        }
    }
    
    @Published var eraserSize: CGFloat = 3.0 {
        didSet {
            if isInitialized {
                updatePdfState()
            }
        }
    }
   
    @Published var highlighterSize: CGFloat = 10.0 {
        didSet {
            if isInitialized {
                updatePdfState()
            }
        }
    }
    @Published var highlighterColor: Color = .yellow {
        didSet {
            if isInitialized {
                updatePdfState()
            }
        }
    }
    @Published var inputMode: InputMode = InputMode.both {
        didSet {
            if isInitialized {
                updatePdfState()
            }
        }
    }
    @Published var recentColors: [Color] = [
        Color.black, Color.blue, Color.red, Color.yellow, Color.green,
    ]
    {
        didSet {
            if isInitialized {
                updatePdfState()
            }
        }
    }

    func setPageIndex(_ index: Int) {
        self.currentPageIndex = index
    }

    func updatePdfState() {
        let context = PersistenceController.shared.pdfStateContainer.viewContext
        let fetchRequest: NSFetchRequest<PdfState> = PdfState.fetchRequest()

        do {
            if let pdfState = try context.fetch(fetchRequest).first {

                pdfState.penSize = Float(self.penSize)
                pdfState.displayDirection =
                    displayDirection == .horizontal ? "horizontal" : "vertical"
                pdfState.inputMode = self.inputMode.stringValue
                pdfState.penColor = self.penColor.toHex()
                pdfState.highlighterColor = self.highlighterColor.toHex()
                pdfState.highlighterSize = Float(self.highlighterSize)
                pdfState.eraserSize = Float(self.eraserSize)
                pdfState.colorHistory1 = self.recentColors[0].toHex()
                pdfState.colorHistory2 = self.recentColors[1].toHex()
                pdfState.colorHistory3 = self.recentColors[2].toHex()
                pdfState.colorHistory4 = self.recentColors[3].toHex()
                pdfState.colorHistory5 = self.recentColors[4].toHex()
                try context.save()
            } else {
                print("PdfState not found")
            }
        } catch {
            print("Failed to update PdfState: \(error)")
        }
    }

    init() {
        ensurePdfStateExists()
        let context = PersistenceController.shared.pdfStateContainer.viewContext
        let fetchRequest: NSFetchRequest<PdfState> = PdfState.fetchRequest()

        do {
            if let pdfState = try context.fetch(fetchRequest).first {

                switch pdfState.displayDirection {
                case "horizontal":
                    self.displayDirection = .horizontal
                case "vertical":
                    self.displayDirection = .vertical
                default:
                    self.displayDirection = .vertical
                }

                switch pdfState.inputMode {
                case "both":
                    self.inputMode = InputMode.both
                case "pencil":
                    self.inputMode = InputMode.pencil
                case "finger":
                    self.inputMode = InputMode.finger
                default:
                    self.inputMode = InputMode.both
                }

                self.penSize = CGFloat(pdfState.penSize)
                self.penColor =
                    Color(hex: pdfState.penColor ?? "#000000") ?? Color.black

                self.highlighterColor = Color(hex: pdfState.highlighterColor ?? "#FFFFFF00") ?? Color.yellow
                self.highlighterSize = CGFloat(pdfState.highlighterSize)
                self.eraserSize = CGFloat(pdfState.eraserSize)
                self.recentColors = [
                    Color(hex: pdfState.colorHistory1 ?? "#000000")
                        ?? Color.black,
                    Color(hex: pdfState.colorHistory2 ?? "#0000FF")
                        ?? Color.blue,
                    Color(hex: pdfState.colorHistory3 ?? "#FF0000")
                        ?? Color.red,
                    Color(hex: pdfState.colorHistory4 ?? "#FFFF00")
                        ?? Color.yellow,
                    Color(hex: pdfState.colorHistory5 ?? "#00FF00")
                        ?? Color.green,
                ]
                isInitialized = true
            } else {
                print("PdfState not found2")
            }
        } catch {
            print("Failed to fetch or createPdfState: \(error)")

        }

    }
    
    
    func ensurePdfStateExists() {
        let context = PersistenceController.shared.pdfStateContainer.viewContext
        let fetchRequest: NSFetchRequest<PdfState> = PdfState.fetchRequest()
        
        do {
            if try context.fetch(fetchRequest).isEmpty {
                // Create a default PdfState
                let newPdfState = PdfState(context: context)
                newPdfState.displayDirection = "vertical"
                newPdfState.inputMode = "both"
                newPdfState.penSize = 1.0
                newPdfState.penColor = "#000000"
                newPdfState.highlighterColor = "#FFFFFF00"
                newPdfState.highlighterSize = 10.0
                newPdfState.eraserSize = 3.0
                newPdfState.colorHistory1 = "#000000"
                newPdfState.colorHistory2 = "#0000FF"
                newPdfState.colorHistory3 = "#FF0000"
                newPdfState.colorHistory4 = "#FFFF00"
                newPdfState.colorHistory5 = "#00FF00"
                
                try context.save()
                print("Default PdfState created.")
            }
        } catch {
            print("Failed to ensure PdfState exists: \(error)")
        }
    }

}
