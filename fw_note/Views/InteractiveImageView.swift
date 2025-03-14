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
    
    private let aspectRatio: CGFloat = 1.0  // Assuming a 1:1 aspect ratio for simplicity
    
    var body: some View {
        ZStack {
            // Image
            if selectMode {
            Image(systemName: "photo")
                .resizable()
                .frame(width: size.width, height: size.height)
                .position(x: position.x, y: position.y)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                          
                                self.position = CGPoint(x: gesture.location.x, y: gesture.location.y)
                            }
                        
                )
            }else{
                Image(systemName: "photo")
                    .resizable()
                    .frame(width: size.width, height: size.height)
                    .position(x: position.x, y: position.y)
                    .allowsHitTesting(false)
            }
            
            if selectMode {
                // Frame with 10px space around the image
                Rectangle()
                    .strokeBorder(Color.blue, lineWidth: 2)
                    .frame(width: size.width + 20, height: size.height + 20)
                    .position(x: position.x, y: position.y)
                   
                
                
                // Top-left circle
                Circle()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.blue)
                    .position(x: position.x - size.width / 2 - 10, y: position.y - size.height / 2 - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newPointTLX = gesture.location.x + 10
                                let newPointTRX = position.x + ((size.width / 2) )
                                let newPointTLY = gesture.location.y + 10
                                let newPointBRY = position.y + ((size.height / 2))
                                
                                let newWidth = newPointTRX - newPointTLX <= 0 ? 0 : newPointTRX - newPointTLX
                                let newHeight = newPointBRY - newPointTLY <= 0 ? 0 : newPointBRY - newPointTLY
                                let newPositionX = newPointTLX + (newWidth/2);
                                let newPositionY = newPointTLY + (newHeight/2);
                                
                                self.size = CGSize(width: newWidth, height: newHeight)
                                self.position = CGPoint(x: newPositionX, y: newPositionY)
                            }
                    )
                
                // Top-right circle
                Circle()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.blue)
                    .position(x: position.x + size.width / 2 + 10, y: position.y - size.height / 2 - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newPointTRX = gesture.location.x - 10
                                let newPointTLX = position.x - size.width / 2
                                let newPointTLY = gesture.location.y + 10
                                let newPointBRY = position.y + size.height / 2
                                
                                let newWidth = max(0, newPointTRX - newPointTLX)
                                let newHeight = max(0, newPointBRY - newPointTLY)
                                let newPositionX = newPointTLX + newWidth / 2
                                let newPositionY = newPointTLY + newHeight / 2
                                
                                self.size = CGSize(width: newWidth, height: newHeight)
                                self.position = CGPoint(x: newPositionX, y: newPositionY)
                            }
                    )
                
                // Bottom-left circle
                Circle()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.blue)
                    .position(x: position.x - size.width / 2 - 10, y: position.y + size.height / 2 + 10)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newPointBLX = gesture.location.x + 10
                                let newPointBRX = position.x + size.width / 2
                                let newPointBLY = gesture.location.y - 10
                                let newPointTLY = position.y - size.height / 2
                                
                                let newWidth = max(0, newPointBRX - newPointBLX)
                                let newHeight = max(0, newPointBLY - newPointTLY)
                                let newPositionX = newPointBLX + newWidth / 2
                                let newPositionY = newPointTLY + newHeight / 2
                                
                                self.size = CGSize(width: newWidth, height: newHeight)
                                self.position = CGPoint(x: newPositionX, y: newPositionY)
                            }
                    )
                
                // Bottom-right circle
                Circle()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.blue)
                    .position(x: position.x + size.width / 2 + 10, y: position.y + size.height / 2 + 10)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newPointBRX = gesture.location.x - 10
                                let newPointBLX = position.x - ((size.width / 2))
                                let newPointBRY = gesture.location.y - 10
                                let newPointTLY = position.y - ((size.height / 2))
                                
                                let newWidth = newPointBRX - newPointBLX <= 0 ? 0 : newPointBRX - newPointBLX
                                let newHeight = newPointBRY - newPointTLY <= 0 ? 0 : newPointBRY - newPointTLY
                                let newPositionX = newPointBLX + (newWidth/2);
                                let newPositionY = newPointTLY + (newHeight/2);
                                
                                self.size = CGSize(width: newWidth, height: newHeight)
                                self.position = CGPoint(x: newPositionX, y: newPositionY)
                            }
                    )
            }
            
          
                

        }
        
    }
}
