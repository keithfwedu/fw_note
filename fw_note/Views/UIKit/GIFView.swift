//
//  GIFView.swift
//  fw_note
//
//  Created by Fung Wing on 31/3/2025.
//

import FLAnimatedImage
import SwiftUI

struct GIFView: UIViewRepresentable {
    var path: String  // Explicit path to the GIF file
    var targetSize: CGSize

    func makeUIView(context: Context) -> UIView {
        // Create a parent UIView to act as a container
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Create the FLAnimatedImageView
        let animatedImageView = FLAnimatedImageView()
        animatedImageView.contentMode = .scaleAspectFit // Change to fit better
        animatedImageView.isUserInteractionEnabled = false // Disable interaction
        animatedImageView.translatesAutoresizingMaskIntoConstraints = true
        
        // Add FLAnimatedImageView to the container
        containerView.addSubview(animatedImageView)

        // Apply constraints to FLAnimatedImageView to match parent UIView's dimensions dynamically
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])


        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Load GIF data and set it to FLAnimatedImageView
        guard let animatedImageView = uiView.subviews.first as? FLAnimatedImageView else {
            print("Failed to locate FLAnimatedImageView.")
            return
        }

        guard let gifData = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            print("Failed to load GIF data from path: \(path)")
            return
        }

        // Create and set the animated GIF
        let animatedImage = FLAnimatedImage(animatedGIFData: gifData, optimalFrameCacheSize: 2, predrawingEnabled: true)
      
        animatedImageView.animatedImage = animatedImage
        
        animatedImageView.frame.size = targetSize
        uiView.frame.size = targetSize
        
       
    }
}

      
            

   
