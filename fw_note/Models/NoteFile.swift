import Foundation
import PDFKit
import UIKit

class NoteFile: ObservableObject, Identifiable, Codable {
    var id = UUID()
    var title: String
    var pdfFilePath: String?
    var thumbnailPath: String?
    private var maxStackSize = 50

    @Published var notePages: [NotePage]  // Initialize to an empty array
    @Published var undoStack: [ActionStack] = []  // Published property properly initialized
    @Published var redoStack: [ActionStack] = []  // Published property properly initialized

    func addToUndo(pageIndex: Int, canvasStack: [CanvasObj]?) {
        // Clone the canvasStack to create an independent copy
        let clonedCanvasStack = canvasStack?.map { $0.clone() }

        print("add to undo \(pageIndex) \(clonedCanvasStack?.count ?? 0)")

        // Create a new ActionStack with the cloned canvasStack
        let action = ActionStack(
            pageIndex: pageIndex, canvasStack: clonedCanvasStack
        )
        
        // Add the action to the undo stack
        undoStack.append(action)
    }


    func undo() {
        let initStackCount: Int = notePages.count
        if undoStack.count > initStackCount + maxStackSize {
            undoStack.removeFirst(undoStack.count - (initStackCount + maxStackSize))  // Remove oldest actions
        }

        guard let currentAction = undoStack.popLast() else {
            print("Nothing to undo")
            return
        }
            print("currentAction: \(currentAction)")
      

        guard let lastAction = undoStack.last else {
            print("Nothing to undo")
            return
        }
            print("lastAction: \(lastAction)")
      


        redoStack.append(currentAction)
        updateStacks(for: lastAction)
    }

    func redo() {
        let initStackCount: Int = notePages.count
        if redoStack.count > maxStackSize {
            redoStack.removeFirst(
                redoStack.count - (initStackCount + maxStackSize))  // Remove oldest actions
        }
        guard let lastAction = redoStack.popLast() else {
            print("Nothing to redo")
            return
        }

        undoStack.append(lastAction)
        updateStacks(for: lastAction)
    }

    private func updateStacks(for action: ActionStack) {
        print("Undoing action for pageIndex: \(action.pageIndex). \((action.canvasStack ?? []).count)")
        guard notePages.indices.contains(action.pageIndex) else {
            print("Index out of bounds")
            return
        }
    
        if action.canvasStack != nil {
            print("undo lineStack");
            notePages[action.pageIndex].canvasStack = action.canvasStack!
        }

      
        self.notePages = notePages
    }

    // Initializer for NoteFile with default title
    init(title: String? = nil, pdfFilePath: String? = nil) {
        // Initialize title
        if let providedTitle = title {
            self.title = providedTitle
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let currentTime = formatter.string(from: Date())
            self.title = "untitled_\(currentTime)"
        }

        self.pdfFilePath = pdfFilePath
        var newNotePages: [NotePage] = []
        // Populate notePages dynamically based on PDF content
        if let pdfFilePath = pdfFilePath {
            let absolutePath = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            )
            .first!.appendingPathComponent(pdfFilePath).path

            if let pdfDocument = PDFDocument(
                url: URL(fileURLWithPath: absolutePath))
            {
                print("pdfDocument.pageCount: \(pdfDocument.pageCount)")

                for pageIndex in 0..<pdfDocument.pageCount {
                    newNotePages.append(NotePage(pageIndex: pageIndex))  // Add pages to the array
                }
            } else {
                print("Failed to load PDF at path: \(absolutePath)")
            }
        }

        self.notePages = newNotePages

        print("notePages Count: \(self.notePages.count)")  // Debugging statement
    }
    
    func save() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        // Serialize the NoteFile instance to JSON data
        let jsonData = try encoder.encode(self)

        // Determine the file path where the JSON will be saved
        guard let pdfFilePath = pdfFilePath else {
            throw NSError(domain: "NoteFile", code: 0, userInfo: [NSLocalizedDescriptionKey: "PDF file path is not set."])
        }
        let absoluteDirectoryPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!.appendingPathComponent(pdfFilePath).deletingLastPathComponent()
        let jsonFileURL = absoluteDirectoryPath.appendingPathComponent("data.json")

        // Write the JSON data to the file
        try FileManager.default.createDirectory(at: absoluteDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        try jsonData.write(to: jsonFileURL)

        print("NoteFile saved successfully at \(jsonFileURL.path)")
    }


    // MARK: - Codable Compliance
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case pdfFilePath
        case thumbnailPath
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        pdfFilePath = try container.decodeIfPresent(
            String.self, forKey: .pdfFilePath)
        thumbnailPath = try container.decodeIfPresent(
            String.self, forKey: .thumbnailPath)
        var newNotePages: [NotePage] = []
        // Populate notePages dynamically based on PDF content
        if let pdfFilePath = pdfFilePath {
            let absolutePath = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            )
            .first!.appendingPathComponent(pdfFilePath).path

            if let pdfDocument = PDFDocument(
                url: URL(fileURLWithPath: absolutePath))
            {
                print("pdfDocument.pageCount: \(pdfDocument.pageCount)")

                for pageIndex in 0..<pdfDocument.pageCount {
                    newNotePages.append(NotePage(pageIndex: pageIndex))  // Add pages to the array
                }
            } else {
                print("Failed to load PDF at path: \(absolutePath)")
            }
        }

        notePages = newNotePages

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(pdfFilePath, forKey: .pdfFilePath)
        try container.encodeIfPresent(thumbnailPath, forKey: .thumbnailPath)
    }
}
