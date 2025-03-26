//
//  CanvasViewWrapper.swift
//  fw_note
//
//  Created by Alex Ng on 20/3/2025.
//


import PDFKit
import SwiftUI

// CanvasViewWrapper Class
class CanvasViewWrapper: UIView {
    var pageIndex: Int
    private var hostingController: UIHostingController<CanvasView>?

    init(frame: CGRect, pageIndex: Int, canvasState: CanvasState, noteFile: NoteFile, notePage: NotePage, scaleFactor: CGFloat) {
        self.pageIndex = pageIndex
        super.init(frame: frame)

        let canvasView = CanvasView(
            pageIndex: pageIndex,
            canvasState: canvasState,
            noteFile: noteFile,
            notePage: notePage,
            scaleFactor: scaleFactor // Pass scale factor to CanvasView
        )

        hostingController = UIHostingController(rootView: canvasView)
        if let hostingView = hostingController?.view {
            hostingView.frame = self.bounds
            hostingView.backgroundColor = .clear
            hostingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
          
            self.addSubview(hostingView)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        hostingController?.view.frame = self.bounds
    }

    func updateScaleFactor(scaleFactor: CGFloat) {
        if let hostingController = hostingController {
            let canvasView = CanvasView(
                pageIndex: pageIndex,
                canvasState: hostingController.rootView.canvasState,
                noteFile: hostingController.rootView.noteFile,
                notePage: hostingController.rootView.notePage,
                scaleFactor: scaleFactor // Update scale factor
            )
            hostingController.rootView = canvasView
        }
    }
}
