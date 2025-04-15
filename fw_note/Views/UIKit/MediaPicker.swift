//
//  MediaPicker.swift
//  fw_note
//
//  Created by Fung Wing on 27/3/2025.
//

import SwiftUI
import Photos

public struct MediaPicker: UIViewControllerRepresentable {
    private let mediaType: UIImagePickerController.SourceType
    private let onMediaSelected: (Data, Bool) -> Void // Second argument indicates if the media is a GIF
    private let onCancel: () -> Void

    public init(mediaType: UIImagePickerController.SourceType, onMediaSelected: @escaping (Data, Bool) -> Void, onCancel: @escaping () -> Void = {}) {
        self.mediaType = mediaType
        self.onMediaSelected = onMediaSelected
        self.onCancel = onCancel
    }

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let mediaPicker = UIImagePickerController()

        mediaPicker.sourceType = mediaType
        mediaPicker.mediaTypes = ["public.image", "com.compuserve.gif"] // Supporting images and GIFs
        mediaPicker.delegate = context.coordinator
        return mediaPicker
    }

    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates required for this implementation
    }

    public func makeCoordinator() -> MediaCoordinator {
        MediaCoordinator(onCancel: self.onCancel, onMediaSelected: self.onMediaSelected)
    }

    public final class MediaCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onCancel: () -> Void
        private let onMediaSelected: (Data, Bool) -> Void

        init(onCancel: @escaping () -> Void, onMediaSelected: @escaping (Data, Bool) -> Void) {
            self.onCancel = onCancel
            self.onMediaSelected = onMediaSelected
        }

        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
            picker.dismiss(animated: true) // Dismiss the picker when canceled
        }

        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard let asset = info[.phAsset] as? PHAsset else {
                if let image = info[.originalImage] as? UIImage {
                    handleImage(image)
                } else {
                    print("Error: Invalid selection or unsupported media type.")
                    onCancel()
                }
                picker.dismiss(animated: true) // Explicitly dismiss the picker
                return
            }
            processAsset(asset)
            picker.dismiss(animated: true) // Explicitly dismiss the picker after processing the asset
        }

        private func handleImage(_ image: UIImage) {
            guard let imageData = image.jpegData(compressionQuality: 1.0) else {
                print("Error: Unable to convert image to JPEG format.")
                onCancel()
                return
            }
            onMediaSelected(imageData, false) // Static image, not GIF
        }

        private func processAsset(_ asset: PHAsset) {
            let imageManager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.isSynchronous = true

            imageManager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                guard let mediaData = data else {
                    print("Error: Unable to retrieve asset data.")
                    self.onCancel()
                    return
                }
                let isGif = ImageHelper.isGIF(data: mediaData)
                self.onMediaSelected(mediaData, isGif)
            }
        }


    }

}
