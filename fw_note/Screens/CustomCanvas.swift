//
//  CustomCanvas.swift
//  fw_note
//
//  Created by Alex Ng on 20/3/2025.
//


import SwiftUI
import UIKit

class CustomCanvas: UIView {

        private var hostingController: UIHostingController<CanvasView>?

        init(frame: CGRect, pageIndex: Int, canvasState: CanvasState, notePage: NotePage) {
            super.init(frame: frame)
            
            // Create the SwiftUI `CanvasView` with the necessary properties
            let canvasView = CanvasView(pageIndex: pageIndex, canvasState: canvasState, notePage: notePage)
            
            // Embed the SwiftUI `CanvasView` in a `UIHostingController`
            let hostingController = UIHostingController(rootView: canvasView)
            self.hostingController = hostingController
            
            // Add the hosting controller's view as a child of this wrapper
            if let hostingView = hostingController.view {
                hostingView.frame = self.bounds
                hostingView.backgroundColor = .clear // Ensure transparent background
                hostingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                self.addSubview(hostingView)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            // Ensure the hosting controller's view matches the size of the wrapper
            hostingController?.view.frame = self.bounds
        }
    }
