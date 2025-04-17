//
//  LassoTool.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//
import SwiftUI

class LassoToolHelper {
    static func moveSelectionPath(selectionPath: [DrawPoint],  translation: CGSize) -> [DrawPoint] {
       return selectionPath.map { point in
           DrawPoint(
                x: point.x + translation.width,
                y: point.y + translation.height
            )
        }
    }
    
    static func moveSelectedLines(selectedLines: [LineObj], translation: CGSize) -> [LineObj] {
        return selectedLines.map { line in
            var updatedLine = line  // Create a mutable copy of the line
            updatedLine.points = line.points.map { point in
                DrawPoint(
                    x: point.x + translation.width,
                    y: point.y + translation.height
                )
            }
            return updatedLine
        }
    }
    
    static func moveLines(lines: [LineObj], selectedLines: [LineObj], translation: CGSize) -> [LineObj] {
        var updatedLines = lines // Create a mutable copy of the original array

        for selectedLine in selectedLines {
            if let index = updatedLines.firstIndex(where: { $0.id == selectedLine.id }) {
                // Create an updated version of the selected line with translated points
                var updatedLine = selectedLine
                updatedLine.points = selectedLine.points.map { point in
                    DrawPoint(
                        x: point.x + translation.width,
                        y: point.y + translation.height
                    )
                }

                // Replace the line in the mutable copy
                updatedLines[index] = updatedLine
            }
        }

        return updatedLines // Return the updated array
    }

    static func moveSelectedImageView(imageStack: [ImageObj], selectedImages: [UUID], translation: CGSize) -> [ImageObj] {
        return imageStack.map { imageObj in
            // Check if the current imageView is selected
            if selectedImages.contains(imageObj.id) {
                // Return a new imageView with updated position
                var updatedImageObj = imageObj
                updatedImageObj.position.x += translation.width
                updatedImageObj.position.y += translation.height
                return updatedImageObj
            } else {
                // Return the imageView unchanged
                return imageObj
            }
        }
    }


   
    static func getSelectedLines(selectionPath: [DrawPoint], lines: [LineObj]) -> [LineObj] {
        let selectionRect = calculateSelectionRect(from: selectionPath);
        return lines.filter { line in
            line.points.contains { point in
                selectionRect.contains(CGPoint(x: point.x, y: point.y))
            }
        }
    }
    
    static func getSelectedImages(selectionPath: [DrawPoint], images: [ImageObj]) -> [UUID] {
        let selectionRect = calculateSelectionRect(from: selectionPath);
        return images.filter { image in
            selectionRect.contains(image.position)
        }.map(\.self.id)
    }
    
    static func getCenterTranslation(
        dragValue: TouchData,
        imageStack: [ImageObj],
        selectedLines: [LineObj],
        selectedImages: [UUID]
    ) -> CGSize {
        // Calculate the center of the selection area
        let selectionCenter = calculateSelectionCenter(
            imageStack: imageStack, selectedLines: selectedLines,
            selectedImages: selectedImages)

        // Offset translation to align the drag with the center
        let centerTranslation = CGSize(
            width: dragValue.location.x - selectionCenter.x,
            height: dragValue.location.y - selectionCenter.y
        )
        
        return centerTranslation;
    }
    
    static func createSelectionBounds(imageStack: [ImageObj],
                                           selectedLines: [LineObj],
                                                  selectedImages: [UUID]
                                                 ) -> [DrawPoint] {
        // Gather all points from selected lines and image positions (with dimensions)
        var allPoints = selectedLines.flatMap { $0.points }
        for image in imageStack {
            if selectedImages.contains(image.id) {
                // Add all four corners of the image to account for its size
                allPoints.append(
                    DrawPoint(
                        x: image.position.x - image.size.width / 2,
                        y: image.position.y - image.size.height / 2))  // Top-left
                allPoints.append(
                    DrawPoint(
                        x: image.position.x + image.size.width / 2,
                        y: image.position.y - image.size.height / 2))  // Top-right
                allPoints.append(
                    DrawPoint(
                        x: image.position.x + image.size.width / 2,
                        y: image.position.y + image.size.height / 2))  // Bottom-right
                allPoints.append(
                    DrawPoint(
                        x: image.position.x - image.size.width / 2,
                        y: image.position.y + image.size.height / 2))  // Bottom-left
            }
        }

        // Ensure there are items to define the rectangle
        guard !allPoints.isEmpty else {
            print("No items to create a rectangle.")
            return []
        }

        // Calculate the bounding box of all points
        let minX = allPoints.map { $0.x }.min() ?? 0
        let maxX = allPoints.map { $0.x }.max() ?? 0
        let minY = allPoints.map { $0.y }.min() ?? 0
        let maxY = allPoints.map { $0.y }.max() ?? 0

        // Add padding of 20 points to the bounding box
        let padding: CGFloat = 20.0

        // Create a rectangular selection path with padding
        return [
            DrawPoint(x: minX - padding, y: minY - padding),  // Top-left
            DrawPoint(x: maxX + padding, y: minY - padding),  // Top-right
            DrawPoint(x: maxX + padding, y: maxY + padding),  // Bottom-right
            DrawPoint(x: minX - padding, y: maxY + padding),  // Bottom-left
            DrawPoint(x: minX - padding, y: minY - padding),  // Close the rectangle
        ]
    }
    
    static func calculateSelectionRect(from selectionPath: [DrawPoint]) -> CGRect {
        return Path { path in
            path.addLines(selectionPath.map { $0.point })
            path.closeSubpath()
        }.boundingRect
    }


    // Checks if a point is inside the current selection area
    static func isPointInsideSelection(_ selectionPath: [DrawPoint], point: DrawPoint) -> Bool {
        guard selectionPath.count > 2 else { return false }  // Ensure the path has enough points to form a closed area

        // Create a CGPath from the selectionPath
        let path = CGMutablePath()
        path.addLines(between: selectionPath.map{ CGPoint(x: $0.x, y: $0.y) })
        path.closeSubpath()  // Close the path to ensure it forms a valid shape

        // Check if the point is inside the closed path
        return path.contains(CGPoint(x: point.x, y: point.y))
    }

    static func calculateSelectionCenter(imageStack: [ImageObj], selectedLines: [LineObj], selectedImages: [UUID]) -> DrawPoint {
        let allPoints =
        selectedLines.flatMap { $0.points }.map{ $0.point }
            + imageStack.filter { selectedImages.contains($0.id) }.map {
                $0.position
            }

        guard !allPoints.isEmpty else { return DrawPoint(x: 0, y: 0) }

        let minX = allPoints.map { $0.x }.min() ?? 0
        let maxX = allPoints.map { $0.x }.max() ?? 0
        let minY = allPoints.map { $0.y }.min() ?? 0
        let maxY = allPoints.map { $0.y }.max() ?? 0

        return DrawPoint(
            x: (minX + maxX) / 2,
            y: (minY + maxY) / 2
        )
    }
}
