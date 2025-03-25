//
//  ColorPickerView.swift
//  pdf_note
//
//  Created by Alex Ng on 8/3/2025.
//
import SwiftUI
import UIKit

struct ColorPickerView: View {
    @Binding var initialColors: [Color] // Input five colors from another view
    var onChanged: (Color) -> Void // Callback to return selected color

    @State private var showColorPicker = [false, false, false, false, false] // Toggles for each picker
    @State private var selectedColor: Color = .clear // Updated when color is picked
    @State private var selectedIndex: Int? = nil // Track the currently selected index
    @State private var scaleEffects: [CGFloat] = [1.0, 1.0, 1.0, 1.0, 1.0] // Scale effect for each circle

    var body: some View {
        HStack {
            ForEach(initialColors.indices, id: \.self) { index in
                ZStack {
                    // Outer circle for selected color
                    if selectedIndex == index {
                        Circle()
                            .stroke(initialColors[index], lineWidth: 4) // Outer border with color
                            .frame(width: 22, height: 22)
                            .animation(.easeInOut, value: selectedIndex) // Smooth animation
                    }

                    // Main color circle
                    Circle()
                        .fill(initialColors[index]) // Display the initial color
                        .frame(width: 16, height: 16)
                        .scaleEffect(scaleEffects[index]) // Apply scaling effect
                        .onTapGesture {
                            selectedColor = initialColors[index] // Select the color
                            selectedIndex = index // Update the selected index
                            onChanged(selectedColor) // Trigger callback

                            // Animate tap start (1 -> 0.9)
                            withAnimation(.easeInOut(duration: 0.1)) {
                                scaleEffects[index] = 0.9
                            }

                            // Animate tap end (0.9 -> 1.2 -> 1)
                            withAnimation(.easeInOut(duration: 0.2).delay(0.1)) {
                                scaleEffects[index] = 1.2
                            }
                            withAnimation(.easeInOut(duration: 0.2).delay(0.3)) {
                                scaleEffects[index] = 1.0
                            }
                        }
                        .onLongPressGesture(minimumDuration: 0.2) {
                            // Animate tap start (1 -> 0.9)
                            withAnimation(.easeInOut(duration: 0.1)) {
                                scaleEffects[index] = 0.9
                            }

                            showColorPicker[index] = true // Open UIKit color picker

                            // Animate tap end (0.9 -> 1.2 -> 1)
                            withAnimation(.easeInOut(duration: 0.2).delay(0.1)) {
                                scaleEffects[index] = 1.2
                            }
                            withAnimation(.easeInOut(duration: 0.2).delay(0.3)) {
                                scaleEffects[index] = 1.0
                            }
                        }
                }
                .background(
                    UIKitColorPicker(
                        isPresented: $showColorPicker[index],
                        selectedColor: Binding(get: {
                            initialColors[index] // Pass the initial color to the UIKit picker
                        }, set: { newColor in
                            initialColors[index] = newColor // Update the initial color
                            selectedColor = newColor // Update the selected color
                            selectedIndex = index // Update the selected index
                            onChanged(selectedColor) // Trigger callback
                        })
                    )
                )
                .padding(.horizontal, 2)
            }
        }
        .padding()
    }
}

struct UIKitColorPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedColor: Color

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController() // Placeholder
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented {
            let colorPicker = UIColorPickerViewController()
            colorPicker.delegate = context.coordinator
            colorPicker.selectedColor = UIColor(selectedColor)

            uiViewController.present(colorPicker, animated: true) {
                isPresented = false
            }
        }
    }

    class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        var parent: UIKitColorPicker

        init(_ parent: UIKitColorPicker) {
            self.parent = parent
        }

        func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
            parent.selectedColor = Color(viewController.selectedColor)
        }

        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
            parent.isPresented = false
        }
    }
}
