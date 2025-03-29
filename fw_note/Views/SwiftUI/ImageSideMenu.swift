//
//  ImageSideMenu.swift
//  fw_note
//
//  Created by Alex Ng on 29/3/2025.
//
import SwiftUI

struct ImageSideMenu: View {
    let width: CGFloat
    let isOpen: Bool
    let menuClose: () -> Void
    @StateObject private var canvasState = CanvasState()
    @State var noteFile: NoteFile

    var body: some View {
        ZStack {
            HStack {
                Spacer().allowsHitTesting(false)
                if isOpen {
                    ImagePickerView(
                        noteFile: noteFile,
                        canvasState: canvasState,
                        onClose: menuClose
                    )
                    .frame(width: self.width)
                    .background(Color(UIColor.systemGray6))
                   
                    .transition(.move(edge: .trailing))  // Slide in from the right
                }
            }
            .animation(.easeInOut, value: isOpen)  // Smooth animation for sliding
        }
    }
}
