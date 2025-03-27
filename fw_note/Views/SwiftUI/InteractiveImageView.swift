//
//  InteractiveImageView.swift
//  fw_note
//
//  Created by Fung Wing on 23/3/2025.
//
import SwiftUI

struct InteractiveImageView: View {
    
    @Binding var imageObj: ImageObj

    @Binding var selectMode: Bool
    @Binding var isFocused: Bool

    var frameSize: CGSize
    var onTap: (_ id: UUID) -> Void
    var onRemove: (_ id: UUID) -> Void
    var onChanged: (_ id: UUID, _ imageObj: ImageObj) -> Void
    var afterChanged: (_ id: UUID, _ imageObj: ImageObj) -> Void

    @State private var lastAngle: CGFloat = 0
    @State private var length: CGFloat = 0

    var body: some View {

        ZStack {
            GeometryReader { geometry in
                // Refresh background image

               ZStack {
                    // Top-left corner
                    if selectMode && isFocused {
                        VStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 20)
                        }
                        .frame(width: 40, height: 40)
                        .background(.clear)
                        .contentShape(Rectangle())
                        .gesture(dragGesture(for: .topLeft))
                        .position(cornerPosition(for: .topLeft, in: geometry))

                    }

                    // Top-right corner
                    if selectMode && isFocused {
                        VStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 20)
                        }
                        .frame(width: 40, height: 40)
                        .background(.clear)
                        .contentShape(Rectangle())
                        .gesture(dragGesture(for: .topRight))
                        .position(cornerPosition(for: .topRight, in: geometry))

                    }
                    // Bottom-left corner
                    if selectMode && isFocused {
                        VStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 20)
                        }
                        .frame(width: 40, height: 40)
                        .background(.clear)
                        .contentShape(Rectangle())
                        .gesture(dragGesture(for: .bottomLeft))
                        .position(
                            cornerPosition(for: .bottomLeft, in: geometry))

                    }
                    // Bottom-right corner
                    if selectMode && isFocused {
                        VStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 20)
                        }
                        .frame(width: 40, height: 40)
                        .background(.clear)
                        .contentShape(Rectangle())
                        .gesture(dragGesture(for: .bottomRight))
                        .position(
                            cornerPosition(for: .bottomRight, in: geometry))
                    }

                    if selectMode && isFocused {
                        Button(action: {
                            // Add your action here, such as removing the view or triggering some logic
                            print("Close button tapped")
                            onRemove(imageObj.id)
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
                        .position(x: self.imageObj.size.width / 2, y: -20)
                    }

                  
                    //Bundle.main.path(forResource: "example", ofType: "png")
                if imageObj.isAnimatedGIF, let imagePath =  self.imageObj.path {
                       MetalImageView(imagePath: imagePath, targetSize: CGSize(width: self.imageObj.size.width, height: self.imageObj.size.height))
                           .frame(width: self.imageObj.size.width, height: self.imageObj.size.height)
                   }
                }
               .background(.blue.opacity(imageObj.isAnimatedGIF ? 0:0.1))
                .border(Color.blue, width: selectMode && isFocused ? 1 : 0)  // Border syncs with scaling
                .frame(
                    width: self.imageObj.size.width,
                    height: self.imageObj.size.height
                )
                .rotationEffect(.degrees(Double(self.imageObj.angle)))
                .gesture(updateMovement(screenSize: frameSize))  // Gesture for movement
                .allowsHitTesting(selectMode)
            }

            //Rotate circle
            if selectMode && isFocused {
                VStack {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 50, height: 50)
                        .opacity(0.2)  // Semi-transparent background
                        .overlay(
                            Image(
                                systemName: "arrow.clockwise"
                                    //systemName: "arrow.up.and.down.and.arrow.left.and.right"
                            )
                            .frame(width: 30, height: 30)
                            .foregroundColor(.blue)  // Icon color
                            .opacity(0.8)  // Adjust icon opacity
                        )
                }
                .offset(x: 0, y: (self.imageObj.size.height / 2) + 50)
                .rotationEffect(
                    .degrees(Double(self.imageObj.angle)), anchor: .center
                )
                .position(
                    x: self.imageObj.size.width / 2,  // Center X position relative to parent
                    y: self.imageObj.size.height / 2  // Center Y position relative to parent
                )
                .gesture(
                    updateRotation()
                )
            }
        }
        .frame(
            width: self.imageObj.size.width,
            height: self.imageObj.size.height
        )
        .position(self.imageObj.position)
        .onAppear {
            length = min(self.imageObj.size.height, self.imageObj.size.width)
        }
        .onChange(of: self.imageObj.size) { _ in
            length = min(self.imageObj.size.height, self.imageObj.size.width)
            onChanged(imageObj.id ,imageObj)
        }
        .onChange(of: self.imageObj.position) { _ in
            onChanged(imageObj.id ,imageObj)
        }
        .onChange(of: self.imageObj.angle) { _ in
            onChanged(imageObj.id ,imageObj)
        }
        .onTapGesture {
            onTap(self.imageObj.id)
        }

    }

    private func updateMovement(screenSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if !isFocused {
                    onTap(self.imageObj.id)
                }

                let transformedTranslation = rotatePoint(
                    CGPoint(
                        x: value.translation.width,
                        y: value.translation.height
                    ),
                    by: -.degrees(Double(0.0))  // Reverse rotation to correctly align movement
                )

                // Update position with constraints
                let newX = self.imageObj.position.x + transformedTranslation.x
                let newY = self.imageObj.position.y + transformedTranslation.y

                // Clamp the new position to stay within the screen or parent bounds
                self.imageObj.position.x = min(max(newX, 0), screenSize.width)
                self.imageObj.position.y = min(max(newY, 0), screenSize.height)
            }
            .onEnded { value in
                let transformedTranslation = rotatePoint(
                    CGPoint(
                        x: value.translation.width,
                        y: value.translation.height
                    ),
                    by: -.degrees(Double(0.0))  // Reverse rotation to correctly align movement
                )

                // Update position with constraints
                let newX = self.imageObj.position.x + transformedTranslation.x
                let newY = self.imageObj.position.y + transformedTranslation.y

                // Clamp the new position to stay within the screen or parent bounds
                self.imageObj.position.x = min(max(newX, 0), screenSize.width)
                self.imageObj.position.y = min(max(newY, 0), screenSize.height)

                afterChanged(imageObj.id,imageObj)
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
                if !isFocused {
                    onTap(self.imageObj.id)
                }
                var theta =
                    (atan2(
                        v.location.x - self.length / 2,
                        self.length / 2 - v.location.y)
                        - atan2(
                            v.startLocation.x - self.length / 2,
                            self.length / 2 - v.startLocation.y)) * 180 / .pi
                if theta < 0 { theta += 360 }
                //print("angle \(self.imageObj.angle)")
                self.imageObj.angle = theta + self.lastAngle
            }
            .onEnded { v in

                self.lastAngle = self.imageObj.angle

                afterChanged(imageObj.id,imageObj)

            }
    }

    // Scaling gesture logic for each corner
    private func dragGesture(for corner: Corner) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if !isFocused {
                    onTap(self.imageObj.id)
                }
                // Transform the drag translation based on the current rotation angle
                let transformedTranslation = rotatePoint(
                    CGPoint(
                        x: value.translation.width, y: value.translation.height),
                    by: -.degrees(Double(0.0))
                )

                // Initialize variables for new dimensions
                var newWidth = imageObj.size.width
                var newHeight = imageObj.size.height

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

           
                // Constrain new width and height to minimum size
                newWidth = max(50, newWidth)
                newHeight = max(50, newHeight)

                // Update state
                self.imageObj.size = CGSize(width: newWidth, height: newHeight)
            }.onEnded { v in
                afterChanged(imageObj.id,imageObj)
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

    func calculateBoundingSize(width: CGFloat, height: CGFloat, angle: CGFloat)
        -> CGSize
    {
        // Convert angle from degrees to radians
        let radians = angle * .pi / 180

        // Calculate the bounding width and height
        let boundingWidth =
            abs(width * cos(radians)) + abs(height * sin(radians))
        let boundingHeight =
            abs(width * sin(radians)) + abs(height * cos(radians))

        return CGSize(width: boundingWidth, height: boundingHeight)
    }

}
