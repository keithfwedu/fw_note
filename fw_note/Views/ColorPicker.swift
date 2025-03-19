//
//  ColorPicker.swift
//  pdf_note
//
//  Created by Alex Ng on 8/3/2025.
//

import SwiftUI
import UIKit

struct ColorPickerView: View {
    @Binding var selectedColor: Color
    @Binding var recentColors: [Color]
    @State private var showColorPicker = false // Toggle to launch the UIKit color picker

    var body: some View {
        VStack {
            // Main Row
            HStack {
                // Selected Color Circle
                Circle()
                    .fill(selectedColor)
                    .frame(width: 30, height: 30)
                    .onTapGesture {
                        showColorPicker = true // Open the UIKit color picker
                    }

                // Recent Colors
                HStack {
                    ForEach(recentColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .onTapGesture {
                                selectedColor = color // Update with recent color
                            }
                    }
                }
                .padding(.horizontal, 5)

                Spacer()
            }
        }
        // Use a UIKit color picker
        .background(
            UIKitColorPicker(
                isPresented: $showColorPicker,
                selectedColor: $selectedColor,
                recentColors: $recentColors
            )
        )
    }
}



struct UIKitColorPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedColor: Color
    @Binding var recentColors: [Color]

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController() // Placeholder to host the color picker
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented {
            let colorPicker = UIColorPickerViewController()
            colorPicker.delegate = context.coordinator
            colorPicker.selectedColor = UIColor(selectedColor)

            // Present the color picker dialog
            uiViewController.present(colorPicker, animated: true) {
                isPresented = false // Reset toggle after presentation
            }
        }
    }

    class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        var parent: UIKitColorPicker

        init(_ parent: UIKitColorPicker) {
            self.parent = parent
        }

        func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
            // Update the selected color
            parent.selectedColor = Color(viewController.selectedColor)
        }

        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
            // Add to recent colors when the picker is dismissed
            let newColor = Color(viewController.selectedColor)
            if !parent.recentColors.contains(newColor) {
                parent.recentColors.insert(newColor, at: 0)
                if parent.recentColors.count > 6 {
                    parent.recentColors.removeLast()
                }
            }
            parent.isPresented = false // Close the picker dialog
        }
    }
}
