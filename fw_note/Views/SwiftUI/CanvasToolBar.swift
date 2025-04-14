//
//  CanvasToolBar.swift
//  fw_note
//
//  Created by Fung Wing on 19/3/2025.
//

import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct FilePicker: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    var onPick: (URL) -> Void

    func makeUIViewController(context: Context)
        -> UIDocumentPickerViewController
    {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            UTType.folder
        ])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIDocumentPickerViewController,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FilePicker

        init(_ parent: FilePicker) {
            self.parent = parent
        }

        func documentPicker(
            _ controller: UIDocumentPickerViewController,
            didPickDocumentsAt urls: [URL]
        ) {
            if let url = urls.first {
                parent.selectedURL = url
                parent.onPick(url)
            }
        }
    }
}

struct CanvasToolBar: View {
    @StateObject var noteFile: NoteFile
    @StateObject var canvasState: CanvasState
    @ObservedObject var noteUndoManager: NoteUndoManager

    @State private var selectedURL: URL?
    @State private var fileName: String = "MyExportedFile.pdf"
    @State private var showAlert = false

    var body: some View {
        HStack {

            HStack(spacing: 10) {  // Fixed spacing between items
                // Scroll Direction Button
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Button(action: toggleDisplayDirection) {
                            Image(
                                systemName: canvasState.displayDirection
                                    == .vertical
                                    ? "arrow.up.and.down"
                                    : "arrow.left.and.right"
                            )
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
                            Slider(
                                value: $canvasState.penSize,
                                in: 1...10,
                                step: 0.1
                            ) {
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
                            Picker(
                                "Eraser Mode",
                                selection: $canvasState.eraseMode
                            ) {
                                Text("Rubber").tag(EraseMode.rubber)
                                Text("Erase Whole Path").tag(EraseMode.whole)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding()
                        }
                        
                        Picker(
                            "Input",
                            selection: $canvasState.inputMode
                        ) {
                            Text("Pencil").tag(InputMode.pencil)
                            Text("Finger").tag(InputMode.finger)
                            Text("Both").tag(InputMode.both)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                    }
                }
                // Flexible Spacer
                Spacer()

                Button(action: {
                    showFilePicker()
                }) {
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
        }.alert("Enter File Name", isPresented: $showAlert) {
            TextField("File Name", text: $fileName)
            Button("Export") {
                if let url = selectedURL {
                    exportFile(to: url)
                }
            }
            Button("Cancel", role: .cancel, action: {})
        }
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
        noteUndoManager.undo()
    }
    func redoAction() {
        print("redoAction")
        noteUndoManager.redo()
    }

    func toggleDisplayDirection() {

        canvasState.displayDirection =
            canvasState.displayDirection == .horizontal
            ? .vertical : .horizontal

        print(
            "Scroll direction changed to \(canvasState.displayDirection == .horizontal ? "Horizontal" : "Vertical")"
        )
    }

    private func showFilePicker() {
        let picker = FilePicker(
            selectedURL: $selectedURL,
            onPick: { url in
                selectedURL = url
                showAlert = true  // Show the alert for renaming
            }
        )
        UIApplication.shared.windows.first?.rootViewController?
            .present(UIHostingController(rootView: picker), animated: true)
    }

    func exportFile(to directoryURL: URL) {
        FileHelper.saveProject(noteFile: noteFile)
        let destinationURL = directoryURL.appendingPathComponent(fileName)

        let pdfFilePath = FileHelper.getPDFPath(projectId: noteFile.id)

        if let originalPDFDocument = PDFDocument(url: URL(fileURLWithPath: pdfFilePath)) {
            // Create a new PDFDocument
            let newPDFDocument = PDFDocument()

            for pageIndex in 0..<originalPDFDocument.pageCount {
                if let page = originalPDFDocument.page(at: pageIndex) {
                    // Screenshot
                    let notePage = noteFile.notePages[pageIndex]
                    let canvasSnapshot = canvasState.canvasPool[pageIndex]
                        .frame(
                            width: notePage.canvasWidth,
                            height: notePage.canvasHeight
                        ).snapshot()

                    // Add screenshot to the page
                    let pageBounds = page.bounds(for: .mediaBox)
                    UIGraphicsBeginImageContextWithOptions(pageBounds.size, false, UIScreen.main.scale)

                    if let context = UIGraphicsGetCurrentContext() {
                        // Flip the context vertically for PDF content
                        context.translateBy(x: 0, y: pageBounds.size.height)
                        context.scaleBy(x: 1.0, y: -1.0)

                        // Draw the existing page content
                        page.draw(
                            with: .mediaBox,
                            to: context
                        )

                        // Reset the transformation for the screenshot
                        context.saveGState() // Save the current state
                        context.translateBy(x: 0, y: pageBounds.size.height)
                        context.scaleBy(x: 1.0, y: -1.0)

                        // Overlay the screenshot
                        canvasSnapshot.draw(
                            in: CGRect(
                                x: 0,
                                y: 0,
                                width: pageBounds.width,
                                height: pageBounds.height
                            )
                        )
                        context.restoreGState() // Restore the saved state
                    }

                    // Get the updated page content
                    if let updatedPageImage = UIGraphicsGetImageFromCurrentImageContext() {
                        UIGraphicsEndImageContext()

                        // Create a new PDFPage with the updated image
                        if let updatedPDFPage = PDFPage(image: updatedPageImage) {
                            newPDFDocument.insert(updatedPDFPage, at: pageIndex)
                        }
                    } else {
                        UIGraphicsEndImageContext()
                        print("Failed to create updated page image.")
                    }
                }
            }

            // Save the new PDFDocument
            do {
                try newPDFDocument.write(to: destinationURL)
                print("New PDF exported successfully to \(destinationURL.path)")
            } catch {
                print("Failed to save the new PDF: \(error)")
            }
        } else {
            print("Failed to load the original PDF document.")
        }
    }



}
