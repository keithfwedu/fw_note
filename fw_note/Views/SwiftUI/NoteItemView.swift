//
//  NoteItemView.swift
//  fw_note
//
//  Created by Fung Wing on 21/3/2025.
//


import SwiftUI
import PDFKit

struct NoteItemView: View {
    let noteFile: NoteFile
    let appSupportDirectory: URL

    var body: some View {
        VStack {
            if let pdfPath = noteFile.pdfFilePath,
               let thumbnail = generateThumbnail(for: appSupportDirectory.appendingPathComponent(pdfPath)) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .cornerRadius(10)
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 150)
                    .cornerRadius(10)
                    .overlay(
                        Text("No Thumbnail")
                            .foregroundColor(.white)
                            .font(.caption)
                    )
            }

            Text(noteFile.title)
                .font(.headline)
                .lineLimit(1)
        }
    }

    // Helper method to generate thumbnail
    private func generateThumbnail(for pdfURL: URL) -> UIImage? {
        guard let pdfDocument = PDFDocument(url: pdfURL),
              let firstPage = pdfDocument.page(at: 0) else {
            return nil
        }

        let thumbnailSize = CGSize(width: 300, height: 400)
        return firstPage.thumbnail(of: thumbnailSize, for: .mediaBox)
    }
}
