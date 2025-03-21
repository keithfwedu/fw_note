//
//  InteractiveImageView.swift
//  pdf_note
//
//  Created by Fung Wing on 7/3/2025.
//

import SwiftUI

struct InteractiveImageView: View {
    @Binding var position: CGPoint
    @Binding var size: CGSize
    @Binding var selectMode: Bool
    @Binding var path: String?

    @State var rotation: Double = 0.0
    @State private var isFocused: Bool = false
    @State private var scale: CGFloat = 1.0  // State for scaling
    private let aspectRatio: CGFloat = 1.0  // Assuming a 1:1 aspect ratio for simplicity

    var body: some View {
        ZStack {
            ZStack {
                // Image

                if let path = path, let uiImage = UIImage(contentsOfFile: path)
                {
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(width: size.width, height: size.height)
                        .allowsHitTesting(selectMode)

                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .frame(width: size.width, height: size.height)
                        .allowsHitTesting(selectMode)

                }

                if selectMode && isFocused {
                    // Frame with 10px space around the image
                    Rectangle()
                        .strokeBorder(Color.blue, lineWidth: 2)
                        .frame(width: size.width + 20, height: size.height + 20)

                    // Top-left circle
                    Circle()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.blue)
                        .position(
                            x: 0,
                            y: 0
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    let newPointTLX = gesture.location.x - 10
                                    let newPointTLY = gesture.location.y - 10
                                    let newPointTRX = size.width + 10
                                    let newPointBRY = size.height + 10

                                    let newWidth = max(
                                        0, newPointTRX - newPointTLX)
                                    let newHeight = max(
                                        0, newPointBRY - newPointTLY)
                                   
                                    let newPositionX = self.position.x - ((newWidth - self.size.width)/2)
                                    let newPositionY = self.position.y - ((newHeight - self.size.height)/2)
                                  
                                  
                                   self.position = CGPoint(
                                        x: newPositionX, y: newPositionY)
                                    self.size = CGSize(
                                        width: newWidth, height: newHeight)
                                }
                        )

                    // Top-right circle
                    Circle()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.blue)
                        .position(
                            x: size.width + 20,
                            y: 0
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    let newPointTRX = gesture.location.x - 10
                                    let newPointTRY = gesture.location.y - 10
                                    let newPointBLX = 0.0
                                    let newPointBLY = size.height

                                    let newWidth = max(
                                        0, newPointTRX - newPointBLX)
                                    let newHeight = max(
                                        0, newPointBLY - newPointTRY)
                                   
                                    let newPositionX = self.position.x + ((newWidth - self.size.width)/2)
                                    let newPositionY = self.position.y - ((newHeight - self.size.height)/2)
                                    self.size = CGSize(
                                        width: newWidth, height: newHeight)
                                    self.position = CGPoint(
                                        x: newPositionX, y: newPositionY)
                                }
                        )

                    // Bottom-left circle
                    Circle()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.blue)
                        .position(
                            x: 0,
                            y: size.height + 20
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    let newPointBLX = gesture.location.x - 10
                                    let newPointBLY = gesture.location.y - 10
                                    let newPointTRX = size.width + 10
                                    let newPointTRY = 0.0

                                    let newWidth = max(
                                        0, newPointTRX - newPointBLX)
                                    let newHeight = max(
                                        0, newPointBLY - newPointTRY)
                                   
                                    let newPositionX = self.position.x - ((newWidth - self.size.width)/2)
                                    let newPositionY = self.position.y + ((newHeight - self.size.height)/2)
                                    self.size = CGSize(
                                        width: newWidth, height: newHeight)
                                    self.position = CGPoint(
                                        x: newPositionX, y: newPositionY)
                                }
                        )

                    // Bottom-right circle
                    Circle()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.blue)
                        .position(
                            x: size.width + 20,
                            y: size.height + 20
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    let newPointBRX = gesture.location.x - 10
                                    let newPointBRY = gesture.location.y - 10
                                    let newPointTLX = 0.0
                                    let newPointTLY = 0.0

                                    let newWidth = max(
                                        0, newPointBRX - newPointTLX)
                                    let newHeight = max(
                                        0, newPointBRY - newPointTLY)
                                   
                                    let newPositionX = self.position.x + ((newWidth - self.size.width)/2)
                                    let newPositionY = self.position.y + ((newHeight - self.size.height)/2)
                                    self.size = CGSize(
                                        width: newWidth, height: newHeight)
                                    self.position = CGPoint(
                                        x: newPositionX, y: newPositionY)
                                }
                        )

                }

            }
            .frame(width: size.width + 20, height: size.height + 20)
            .background(Color.blue.opacity(0.1))
            .rotationEffect(Angle(degrees: rotation), anchor: .center)

            .onTapGesture {
                isFocused = true  // Focus the image on tap
            }

        }.position(self.position)
            .gesture(
                SimultaneousGesture(
                    DragGesture()
                        .onChanged { gesture in
                            self.position = CGPoint(
                                x: gesture.location.x,
                                y: gesture.location.y
                            )
                        },
                    RotationGesture()
                        .onChanged { angle in
                            self.rotation = angle.degrees
                        }
                )
            )
    }
}

/*





/* HStack {
 Spacer()
 Button(action: {
     // Add your delete image logic here
     self.path = nil  // Example: Clear the image path
     self.isFocused = false
 }) {
     Image(systemName: "xmark.circle.fill")
         .resizable()
         .frame(width: 30, height: 30)
         .foregroundColor(.red)
 }
 Spacer()
}

.background(Color.white)
.frame(width: size.width + 20, height: 50)
.position(

 y: size.height + 5
)*/

 */
