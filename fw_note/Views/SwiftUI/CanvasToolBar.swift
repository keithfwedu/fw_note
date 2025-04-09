//
//  CanvasToolBar.swift
//  fw_note
//
//  Created by Fung Wing on 19/3/2025.
//

import SwiftUI
import PDFKit

struct CanvasToolBar: View {
    @StateObject var noteFile: NoteFile
    @StateObject var canvasState: CanvasState

    var body: some View {
        HStack {
            
            HStack(spacing: 10) {  // Fixed spacing between items
                // Scroll Direction Button
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Button(action: toggleDisplayDirection) {
                            Image(
                                systemName: canvasState.displayDirection == .vertical
                                ? "arrow.up.and.down": "arrow.left.and.right" )
                        }
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .accessibilityLabel("Change Scroll Direction")
                        
                        // Tool Buttons
                        Button(action: selectPenTool) {
                            Image(systemName: "pencil")
                        }
                        .frame(width: 40, height: 40)
                        .background(
                            canvasState.canvasMode == CanvasMode.draw
                            ? Color.blue.opacity(0.2) : Color.clear
                        )
                        .cornerRadius(8)
                        
                        Button(action: toggleLaserMode) {
                            Image(systemName: "rays")
                        }
                        .frame(width: 40, height: 40)
                        .background(
                            canvasState.canvasMode == CanvasMode.laser
                            ? Color.blue.opacity(0.2) : Color.clear
                        )
                        .cornerRadius(8)
                        
                        Button(action: selectEraserTool) {
                            Image(systemName: "trash")
                        }
                        .frame(width: 40, height: 40)
                        .background(
                            canvasState.canvasMode == CanvasMode.eraser
                            ? Color.blue.opacity(0.2) : Color.clear
                        )
                        .cornerRadius(8)
                        
                        Button(action: selectLassorTool) {
                            Image(systemName: "lasso")
                        }
                        .frame(width: 40, height: 40)
                        .background(
                            canvasState.canvasMode == CanvasMode.lasso
                            ? Color.blue.opacity(0.2) : Color.clear
                        )
                        .cornerRadius(8)
                        
                        
                        
                        if canvasState.canvasMode != CanvasMode.laser {
                            Slider(value: $canvasState.penSize, in: 1...10, step: 0.1) {
                                Text("Tool Size")
                            }
                            .frame(width: 100)
                        }
                        
                        // Conditional Color Picker
                        if canvasState.canvasMode == CanvasMode.draw {
                            ColorPickerView(
                                initialColors: $canvasState.recentColors,  // Input five colors from another view
                                onChanged: { selectedColor in
                                    canvasState.penColor = selectedColor
                                }
                                
                            )
                        }
                        if canvasState.canvasMode == CanvasMode.eraser {
                            Picker("Eraser Mode", selection: $canvasState.eraseMode) {
                                Text("Rubber").tag(EraseMode.rubber)
                                Text("Erase Whole Path").tag(EraseMode.whole)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding()
                        }
                    }
                }
                // Flexible Spacer
                Spacer()

                // Undo/Redo Buttons
               
                // Save PDF Button
                Button(action: savePDF) {
                    Image(systemName: "square.and.arrow.down")
                }
                .frame(width: 40, height: 40)
              
                // Flexible Spacer
                Spacer()
                Button(action: undoAction) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .frame(width: 40)
                Button(action: redoAction) {
                    Image(systemName: "arrow.uturn.forward")
                }
                .frame(width: 40)
                Button(action: addImage) {
                    Image(systemName: "photo")
                }
                .frame(width: 40, height: 40)
                .cornerRadius(8)
                .disabled(canvasState.canvasMode == CanvasMode.laser)
            }
            .frame(height: 70)
            .background(Color(UIColor.systemGray6))  // Toolbar background
        }
    }

    // Mock functions
    func savePDF() {
        print("Save PDF")
        FileHelper.saveProject(noteFile: noteFile)
       // print("draw2 \(canvasState.canvasPool[0])")
        let pageSize = CGSize(
            width:  noteFile.notePages[0].canvasWidth,
            height:  noteFile.notePages[0].canvasHeight
            )
      let canvasSnapshot = canvasState.canvasPool[0].frame(
            width: pageSize.width,
            height:pageSize.height
        ).snapshot()
       
        let pdfFilePath = FileHelper.getPDFPath(projectId:  noteFile.id)
        if let pdfDocument = PDFDocument(url: URL(fileURLWithPath: pdfFilePath))
        {
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
            
            
            let pdfImage = page.thumbnail(of: pageSize, for: .mediaBox)
            
            guard
                let combinedImage = combineImages(
                    baseImage: pdfImage,
                    overlayImage: canvasSnapshot
                ) else {
                print("Error combining images")
                return
            }
            
            let currentUserId = FileHelper.getCurrentUserId() // Fetch the current user ID
            let baseDirectory = FileHelper.getBaseDirectory() // Base directory of your app
            
            // Define the project and images directories
            let projectDirectory = baseDirectory.appendingPathComponent(
                "users/\(currentUserId)/projects/\(noteFile.id.uuidString)",
                isDirectory: true
            )
            let thumbnailPath = projectDirectory.appendingPathComponent(
                "thumbnail.jpg"
            )
            do {
                try combinedImage.pngData()?.write(to: thumbnailPath)
            } catch {
                print(error)
            }
        }

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
    
    func selectPenTool() {
        print("selectPenTool")
        canvasState.canvasMode = CanvasMode.draw
    }
    func toggleLaserMode() {
        print("toggleLaserMode")
        canvasState.canvasMode = CanvasMode.laser
    }
    func selectEraserTool() {
        print("selectEraserTool")
        canvasState.canvasMode = CanvasMode.eraser
    }
    func selectEraserFillTool() { print("selectEraserFillTool") }
    func selectLassorTool() {
        print("selectLassorTool")
        canvasState.canvasMode = CanvasMode.lasso
    }
    func addImage() {
        print("addImage")
  
        canvasState.showImagePicker.toggle()
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

        canvasState.displayDirection =
            canvasState.displayDirection == .horizontal
            ? .vertical : .horizontal
        
        
        print(
            "Scroll direction changed to \(canvasState.displayDirection == .horizontal ? "Horizontal" : "Vertical")"
        )
    }
    
    func exportFile() {
       
      /*  guard let relativePath = noteFile.pdfFilePath else {
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
        guard let originalDocument = PDFDocument(url: pdfFileUrl) else {
            print("Error opening PDF file")
            return
        }

        // Create a new editable PDFDocument
        let pdfDocument = PDFDocument()

        // Copy pages from the original document into the cloned document
        for index in 0..<originalDocument.pageCount {
            if let page = originalDocument.page(at: index) {
                pdfDocument.insert(page, at: index)
            }
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

        // Capture the Canvas snapshot
        let pageRect = page.bounds(for: .mediaBox)
        let canvasSnapshot = canvas.frame(
            width: pageRect.width,
            height: pageRect.height
        ).snapshot()
        // Create a new PDF page by combining the original page content and Canvas snapshot
        let mutableData = NSMutableData()
        UIGraphicsBeginPDFContextToData(mutableData, pageRect, nil)
        UIGraphicsBeginPDFPageWithInfo(pageRect, nil)

        guard let context = UIGraphicsGetCurrentContext() else {
            print("Error: Could not get graphics context")
            return
        }

        // Apply rotation handling explicitly
        context.saveGState()  // Save the current graphics state
        context.translateBy(x: 0, y: pageRect.height)  // Move origin to the bottom-left corner
        context.scaleBy(x: 1.0, y: -1.0)  // Flip the y-axis vertically

        page.draw(with: .mediaBox, to: context)
        context.restoreGState()

        // Draw the Canvas snapshot on top of the page
        canvasSnapshot.draw(in: pageRect)

        UIGraphicsEndPDFContext()

        // Use the updated PDF data to create a new PDFPage
        guard
            let updatedPage = PDFDocument(data: mutableData as Data)?
                .page(at: 0)
        else {
            print("Error: Could not create updated PDF page")
            return
        }

        // Replace the original page with the updated one
        pdfDocument.removePage(at: canvasState.currentPageIndex)
        pdfDocument.insert(
            updatedPage,
            at: canvasState.currentPageIndex
        )

        // Export the updated PDF
        let tempDirectory = FileManager.default.temporaryDirectory
        let exportUrl = tempDirectory.appendingPathComponent(
            "UpdatedDocument.pdf"
        )

        if pdfDocument.write(to: exportUrl) {
            print("PDF exported successfully to \(exportUrl)")

            // Present the Document Picker to let the user save/export the file
            let picker = UIDocumentPickerViewController(forExporting: [
                exportUrl
            ])
            if let windowScene = UIApplication.shared.connectedScenes
                .first as? UIWindowScene
            {
                if let window = windowScene.windows.first {
                    picker.delegate =
                        window.rootViewController
                        as? UIDocumentPickerDelegate
                    window.rootViewController?.present(
                        picker,
                        animated: true,
                        completion: nil
                    )
                }
            }

        } else {
            print("Error: Could not save updated PDF")
        }*/
    }
}
