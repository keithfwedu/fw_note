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
    
    @ObservedObject var imageState: ImageState
    @ObservedObject var canvasState: CanvasState
    @ObservedObject var noteUndoManager: NoteUndoManager
   
    @State var noteFile: NoteFile

    var body: some View {
        ZStack {
            HStack {
                Spacer().allowsHitTesting(false)
                if isOpen {
                    ImagePickerView(
                        noteFile: noteFile,
                        imageState: imageState,
                        canvasState: canvasState,
                        noteUndoManager: noteUndoManager,
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
