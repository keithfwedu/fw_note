//
//  NoteItemView.swift
//  fw_note
//
//  Created by Fung Wing on 21/3/2025.
//

import PDFKit
import SwiftUI

struct NoteItemView: View {
    let noteFile: NoteFile

    var body: some View {
        VStack {
            if let thumbnail = FileHelper.getThumbnailData(
                projectId: noteFile.id
            ) {
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

}
