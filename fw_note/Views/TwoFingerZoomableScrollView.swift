//
//  TwoFingerZoomableScrollView.swift
//  fw_note
//
//  Created by Fung Wing on 20/3/2025.
//

import SwiftUI
import UIKit

struct TwoFingerZoomableScrollView<Content: View>: UIViewRepresentable {
    let content: Content
    let minZoom: CGFloat
    let maxZoom: CGFloat

    init(minZoom: CGFloat = 0.7, maxZoom: CGFloat = 2.0, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.minZoom = minZoom
        self.maxZoom = maxZoom
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.bounces = true
        scrollView.minimumZoomScale = minZoom
        scrollView.maximumZoomScale = maxZoom
        scrollView.delegate = context.coordinator

        // Configure scrollView to require 2 fingers for scrolling
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
        scrollView.panGestureRecognizer.maximumNumberOfTouches = 2

        // Add SwiftUI content as a subview
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(hostingController.view)

        // Constrain the content to the scroll view
        NSLayoutConstraint.activate([
            hostingController.view.centerXAnchor.constraint(equalTo: scrollView.contentLayoutGuide.centerXAnchor), // Center horizontally
            hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),         // Align to the top
            hostingController.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),       // Match the width of the scroll view
            hostingController.view.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor) // Ensure sufficient height
        ])

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // Ensure content size and offset are updated during view updates
        if let hostingView = uiView.subviews.first {
            hostingView.layoutIfNeeded()

            // Adjust content size dynamically
            let contentSize = hostingView.intrinsicContentSize
            uiView.contentSize = CGSize(width: max(contentSize.width, uiView.frame.width),
                                        height: max(contentSize.height, uiView.frame.height))

            // Ensure content starts at the top
            uiView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            // Specify the view to zoom
            return scrollView.subviews.first
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let zoomableView = scrollView.subviews.first else { return }

            // Calculate horizontal offset to center content horizontally
            let offsetX = max((scrollView.bounds.size.width - zoomableView.frame.width) / 2, 0)
            let offsetY: CGFloat = 0 // Keep the content top-aligned

            zoomableView.center = CGPoint(x: scrollView.contentSize.width / 2 + offsetX,
                                          y: zoomableView.frame.size.height / 2 + offsetY)

            // Dynamically update content size during zoom
            scrollView.contentSize = CGSize(width: zoomableView.frame.width,
                                            height: zoomableView.frame.height)
        }

    }
}
