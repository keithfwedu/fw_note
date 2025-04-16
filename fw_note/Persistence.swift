//
//  Persistence.swift
//  fw_note
//
//  Created by Fung Wing on 9/4/2025.
//

import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    // Preview property for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let appStateViewContext = controller.appStateContainer.viewContext
        let appState = AppState(context: appStateViewContext)
        appState.currentUserId = "guest"
        do {
            try appStateViewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("appState - Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        let pdfStateViewContext = controller.pdfStateContainer.viewContext
        let pdfState = PdfState(context: pdfStateViewContext)
        pdfState.displayDirection = "vertical"
        pdfState.inputMode = "both"
        pdfState.penColor = "#000000"
        pdfState.penSize = 3.0
        pdfState.colorHistory1 = "#000000"
        pdfState.colorHistory2 = "#0000FF"
        pdfState.colorHistory3 = "#FF0000"
        pdfState.colorHistory4 = "#FFFF00"
        pdfState.colorHistory5 = "#00FF00"
        
        do {
            try pdfStateViewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("pdfState - Unresolved error \(nsError), \(nsError.userInfo)")
        }

        return controller
    }()

    let appStateContainer: NSPersistentContainer
    let pdfStateContainer: NSPersistentContainer
    

    init(inMemory: Bool = false) {
        appStateContainer = NSPersistentContainer(name: "AppState") // Replace with your Core Data model name
        pdfStateContainer = NSPersistentContainer(name: "PdfState") // Replace with your Core Data model name
        if inMemory {
            appStateContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
            pdfStateContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        appStateContainer.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("appStateContainer - Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        pdfStateContainer.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("pdfStateContainer - Unresolved error \(error), \(error.userInfo)")
            }
        }
        
       
    }
}
