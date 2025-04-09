import Foundation
import PDFKit
import UIKit

class NoteFile: ObservableObject, Identifiable, Codable {
    var id: UUID
    var title: String

    private var maxStackSize = 50

    @Published var notePages: [NotePage] = []
    @Published var undoStack: [ActionStack] = []
    @Published var redoStack: [ActionStack] = []

    // Initializer for NoteFile with default title and optional PDF file path
    init(id: UUID, title: String? = nil) {
        self.id = id
        if let providedTitle = title {
            self.title = providedTitle
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            self.title = "untitled_\(formatter.string(from: Date()))"
        }

        // Load and reconcile notePages with the PDF file if provided
        let pdfFilePath = FileHelper.getPDFPath(projectId: id)
        print(pdfFilePath);
        if let pdfDocument = PDFDocument(url: URL(fileURLWithPath: pdfFilePath))
        {
            reconcileNotePages(with: pdfDocument)
        } else {
            print("Failed to load PDF at path: \(pdfFilePath)")
        }

    }

    // MARK: - Codable Compliance
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case notePages
        case undoStack
        case redoStack
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)

        // Decoding Published properties
        notePages = try container.decode([NotePage].self, forKey: .notePages)
        undoStack = try container.decode([ActionStack].self, forKey: .undoStack)
        redoStack = try container.decode([ActionStack].self, forKey: .redoStack)
        // Load and reconcile notePages with the PDF file if provided
        let pdfFilePath = FileHelper.getPDFPath(projectId: id)

        if let pdfDocument = PDFDocument(url: URL(fileURLWithPath: pdfFilePath))
        {
            reconcileNotePages(with: pdfDocument)
        } else {
            print("Failed to load PDF at path: \(pdfFilePath)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)

        // Encoding Published properties
        try container.encode(notePages, forKey: .notePages)
        try container.encode(undoStack, forKey: .undoStack)
        try container.encode(redoStack, forKey: .redoStack)
    }

    // Reconcile notePages with PDF pages
    func reconcileNotePages(with pdfDocument: PDFDocument) {
        let pdfPageCount = pdfDocument.pageCount
        if notePages.count != pdfPageCount {
            var newNotePages: [NotePage] = []
            for pageIndex in 0..<pdfPageCount {
                if pageIndex < notePages.count {
                    // Use existing NotePage if available
                    newNotePages.append(notePages[pageIndex])
                } else {
                    // Otherwise, create a new NotePage
                    newNotePages.append(NotePage(pageIndex: pageIndex))
                }
            }
            notePages = newNotePages
        }
    }

    func addToUndo(pageIndex: Int, canvasStack: [CanvasObj]?) {
        // Clone the canvasStack to create an independent copy
        let clonedCanvasStack = canvasStack?.map { $0.clone() }

        print("add to undo \(pageIndex) \(clonedCanvasStack?.count ?? 0)")

        // Create a new ActionStack with the cloned canvasStack
        let action = ActionStack(
            pageIndex: pageIndex,
            canvasStack: clonedCanvasStack
        )

        // Add the action to the undo stack
        undoStack.append(action)
    }

    func undo() {
        let initStackCount: Int = notePages.count
        if undoStack.count > initStackCount + maxStackSize {
            undoStack.removeFirst(
                undoStack.count - (initStackCount + maxStackSize)
            )  // Remove oldest actions
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
                redoStack.count - (initStackCount + maxStackSize)
            )  // Remove oldest actions
        }
        guard let lastAction = redoStack.popLast() else {
            print("Nothing to redo")
            return
        }

        undoStack.append(lastAction)
        updateStacks(for: lastAction)
    }

    private func updateStacks(for action: ActionStack) {
        print(
            "Undoing action for pageIndex: \(action.pageIndex). \((action.canvasStack ?? []).count)"
        )
        guard notePages.indices.contains(action.pageIndex) else {
            print("Index out of bounds")
            return
        }

        if action.canvasStack != nil {
            print("undo lineStack")
            notePages[action.pageIndex].canvasStack = action.canvasStack!
        }

        self.notePages = notePages
    }

}
