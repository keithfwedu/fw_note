//
//  PdfHelper.swift
//  fw_note
//
//  Created by Fung Wing on 17/4/2025.
//

import SwiftUI
import PDFKit

class PdfHelper {
    static func clonePdfDocument(originalDocument: PDFDocument?) -> PDFDocument? {
        guard let originalDocument = originalDocument,
              let documentData = originalDocument.dataRepresentation(),
              let clonedDocument = PDFDocument(data: documentData)
        else {
            //print("Failed to clone the PDFDocument.")
            return nil
        }
        
        //print("Successfully cloned PDFDocument!")
        return clonedDocument
    }
    
    
    
    

}
