import Foundation
import PDFKit
import UIKit

class NoteFile: ObservableObject, Identifiable, Codable {
    var id: UUID
    var title: String
    var createdAt: Date

    @Published var notePages: [NotePage] = []

    // Initializer for NoteFile with default title and optional PDF file path
    init(id: UUID, title: String? = nil) {
        self.id = id
        if let providedTitle = title {
            self.title = providedTitle
        } else {
            self.title = "untitled"
        }

        self.createdAt = Date()

        // Load and reconcile notePages with the PDF file if provided
        let pdfFilePath = FileHelper.getPDFPath(projectId: id)
        if let pdfDocument = PDFDocument(url: URL(fileURLWithPath: pdfFilePath))
        {
            reconcileNotePages(with: pdfDocument)
        } else {
            //print("Failed to load PDF at path: \(pdfFilePath)")
        }

    }
    
  

    // MARK: - Codable Compliance
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case createdAt
        case notePages
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        // Decoding Published properties
        notePages = try container.decode([NotePage].self, forKey: .notePages)

        // Load and reconcile notePages with the PDF file if provided
        let pdfFilePath = FileHelper.getPDFPath(projectId: id)

        if let pdfDocument = PDFDocument(url: URL(fileURLWithPath: pdfFilePath))
        {
            reconcileNotePages(with: pdfDocument)
        } else {
            //print("Failed to load PDF at path: \(pdfFilePath)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(createdAt, forKey: .createdAt)
        // Encoding Published properties
        try container.encode(notePages, forKey: .notePages)

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

}
