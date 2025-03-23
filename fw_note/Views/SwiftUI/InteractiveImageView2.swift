//
//  InteractiveImageView2.swift
//  fw_note
//
//  Created by Fung Wing on 23/3/2025.
//
import SwiftUI

struct InteractiveImageView2: View {

    @State private var viewOffset: CGSize = .zero
    @State private var rotationAngle: Angle = .zero
    @State private var angle: CGFloat = 0
    @State private var lastAngle: CGFloat = 0

    @State private var length: CGFloat
    @State private var viewSize: CGSize

    init(width: CGFloat, height: CGFloat) {

        _length = State(initialValue: max(height, width))
        _viewSize = State(initialValue: CGSize(width: width, height: height))
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in

                // Refresh background image

                ZStack {
                    // Top-left corner
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 20, height: 20)

                        .gesture(dragGesture(for: .topLeft))
                        .position(cornerPosition(for: .topLeft, in: geometry))

                    // Top-right corner
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 20, height: 20)

                        .gesture(dragGesture(for: .topRight))
                        .position(cornerPosition(for: .topRight, in: geometry))

                    // Bottom-left corner
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 20, height: 20)

                        .gesture(dragGesture(for: .bottomLeft))
                        .position(
                            cornerPosition(for: .bottomLeft, in: geometry))

                    // Bottom-right corner
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 20, height: 20)

                        .gesture(dragGesture(for: .bottomRight))
                        .position(
                            cornerPosition(for: .bottomRight, in: geometry))

                    Button(action: {
                        // Add your action here, such as removing the view or triggering some logic
                        print("Close button tapped")
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 30, height: 30)
                            Image(systemName: "xmark")
                                .foregroundColor(.white)  // Icon color
                                .font(.system(size: 16))  // Optional: Adjust size
                        }
                    }

                    .position(x: viewSize.width / 2, y: -20)

                    // ImageView inside the frame
                    Image(systemName: "photo.fill")
                        .resizable()

                        .frame(width: viewSize.width, height: viewSize.height)
                        .position(x: viewSize.width / 2, y: viewSize.height / 2)
                    ZStack {
                        Image(systemName: "arrow.clockwise")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)  // Border color
                            .frame(
                                width: geometry.size.width * 0.8,
                                height: geometry.size.height * 0.8
                            )
                            .position(
                                x: geometry.size.width / 2,
                                y: geometry.size.height / 2)

                    }.position(
                        x: geometry.size.width / 2, y: geometry.size.height / 2
                    ).opacity(0.2)
                        .background(.blue.opacity(0.5))
                }

                .border(Color.blue, width: 1)  // Border syncs with scaling
                .frame(width: viewSize.width, height: viewSize.height)
                .rotationEffect(.degrees(Double(self.angle)))
                .gesture(
                    updateRotation()
                )

            }

            Circle()
                .fill(Color.gray)
                .frame(width: 50, height: 50)

                .opacity(0.2)  // Semi-transparent background
                .overlay(
                    Image(
                        systemName: "arrow.up.and.down.and.arrow.left.and.right"
                    )
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)  // Icon color
                    .opacity(0.8)  // Adjust icon opacity
                )

                .gesture(updateMovement())  // Gesture for movement

        }.frame(width: viewSize.width, height: viewSize.height).offset(
            viewOffset)
    }

    private func updateMovement() -> some Gesture {
        DragGesture()
            .onChanged { value in
                let transformedTranslation = rotatePoint(
                    CGPoint(
                        x: value.translation.width, y: value.translation.height),
                    by: -rotationAngle  // Reverse rotation to correctly align movement
                )

                // Update the view offset based on the drag translation
                viewOffset.width += transformedTranslation.x
                viewOffset.height += transformedTranslation.y

            }
            .onEnded { value in
                let transformedTranslation = rotatePoint(
                    CGPoint(
                        x: value.translation.width, y: value.translation.height),
                    by: -rotationAngle  // Reverse rotation to correctly align movement
                )

                viewOffset.width += transformedTranslation.x
                viewOffset.height += transformedTranslation.y
            }
    }

    // Calculate corner positions
    private func cornerPosition(for corner: Corner, in geometry: GeometryProxy)
        -> CGPoint
    {
        switch corner {
        case .topLeft:
            return CGPoint(x: 0, y: 0)
        case .topRight:
            return CGPoint(x: geometry.size.width, y: 0)
        case .bottomLeft:
            return CGPoint(x: 0, y: geometry.size.height)
        case .bottomRight:
            return CGPoint(x: geometry.size.width, y: geometry.size.height)
        }
    }

    private func updateRotation() -> some Gesture {
        DragGesture()
            .onChanged { v in
                var theta =
                    (atan2(
                        v.location.x - self.length / 2,
                        self.length / 2 - v.location.y)
                        - atan2(
                            v.startLocation.x - self.length / 2,
                            self.length / 2 - v.startLocation.y)) * 180 / .pi
                if theta < 0 { theta += 360 }
                self.angle = theta + self.lastAngle
            }
            .onEnded { v in
                self.lastAngle = self.angle
            }
    }

    // Scaling gesture logic for each corner
    private func dragGesture(for corner: Corner) -> some Gesture {
        DragGesture()
            .onChanged { value in
                print("rotationAngle \(rotationAngle)")
                // Transform the drag translation based on the current rotation angle
                let transformedTranslation = rotatePoint(
                    CGPoint(
                        x: value.translation.width, y: value.translation.height),
                    by: -rotationAngle
                )

                // Initialize variables for new dimensions
                var newWidth = viewSize.width
                var newHeight = viewSize.height

                // Use incremental changes instead of total translation
                let deltaX = transformedTranslation.x
                let deltaY = transformedTranslation.y
                switch corner {
                case .topLeft:
                    newWidth -= deltaX
                    newHeight -= deltaY

                case .topRight:
                    newWidth += deltaX
                    newHeight -= deltaY

                case .bottomLeft:
                    newWidth -= deltaX
                    newHeight += deltaY

                case .bottomRight:
                    newWidth += deltaX
                    newHeight += deltaY

                }

                print("\(deltaX) \(deltaY) \(newWidth), \(newHeight)")
                // Constrain new width and height to minimum size
                newWidth = max(50, newWidth)
                newHeight = max(50, newHeight)

                // Update state
                viewSize = CGSize(width: newWidth, height: newHeight)
            }
    }

    private func rotatePoint(_ point: CGPoint, by angle: Angle) -> CGPoint {
        let radians = CGFloat(angle.radians)
        let x = point.x * cos(radians) - point.y * sin(radians)
        let y = point.x * sin(radians) + point.y * cos(radians)
        return CGPoint(x: x, y: y)
    }

    // Enum for identifying corners
    private enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }
}
