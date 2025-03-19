import Foundation
import PDFKit
import UIKit

class NoteFile: ObservableObject, Identifiable, Codable {
    var id = UUID()
    var title: String
    var pdfFilePath: String?
    @Published var notePages: [NotePage] // Initialize to an empty array
    @Published var undoStack: [ActionStack] = [] // Published property properly initialized
    @Published var redoStack: [ActionStack] = [] // Published property properly initialized
    var thumbnailPath: String?

    private var maxStackSize = 50

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
            let absolutePath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first!.appendingPathComponent(pdfFilePath).path

            if let pdfDocument = PDFDocument(url: URL(fileURLWithPath: absolutePath)) {
                print("pdfDocument.pageCount: \(pdfDocument.pageCount)")

                for pageIndex in 0..<pdfDocument.pageCount {
                    newNotePages.append(NotePage(pageIndex: pageIndex)) // Add pages to the array
                }
            } else {
                print("Failed to load PDF at path: \(absolutePath)")
            }
        }
        
        self.notePages = newNotePages;

        print("notePages Count: \(self.notePages.count)") // Debugging statement
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
        pdfFilePath = try container.decodeIfPresent(String.self, forKey: .pdfFilePath)
        thumbnailPath = try container.decodeIfPresent(String.self, forKey: .thumbnailPath)
        var newNotePages: [NotePage] = []
        // Populate notePages dynamically based on PDF content
        if let pdfFilePath = pdfFilePath {
            let absolutePath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first!.appendingPathComponent(pdfFilePath).path

            if let pdfDocument = PDFDocument(url: URL(fileURLWithPath: absolutePath)) {
                print("pdfDocument.pageCount: \(pdfDocument.pageCount)")

                for pageIndex in 0..<pdfDocument.pageCount {
                    newNotePages.append(NotePage(pageIndex: pageIndex)) // Add pages to the array
                }
            } else {
                print("Failed to load PDF at path: \(absolutePath)")
            }
        }
        
        notePages = newNotePages;
        undoStack = []
        redoStack = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(pdfFilePath, forKey: .pdfFilePath)
        try container.encodeIfPresent(thumbnailPath, forKey: .thumbnailPath)
    }
}
