//
//  DropZoneView.swift
//  fw_note
//
//  Created by Fung Wing on 7/4/2025.
//

import SwiftUI

struct DropZoneView: View {
    @Binding var isDraggingOver: Bool
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.5))  // Blue background with opacity
                    )
                    .frame(
                        width: geometry.size.width * 0.8,
                        height: geometry.size.height * 0.8
                    )  // 80% of parent view size

                Text(isDraggingOver ? "Dragging over..." : "Drop PDF here")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .allowsHitTesting(!isDraggingOver)

        }
    }
}
