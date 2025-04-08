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
    
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(
                in: controller.view.bounds,
                afterScreenUpdates: true
            )
        }
    }
}
