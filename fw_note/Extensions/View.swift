//
//  View.swift
//  fw_note
//
//  Created by Fung Wing on 21/3/2025.
//

import SwiftUI

extension View {
    func withDeleteContextMenu(
        noteFile: NoteFile, deleteAction: @escaping (NoteFile) -> Void
    ) -> some View {
        self.contextMenu {
            Button(role: .destructive) {
                deleteAction(noteFile)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
