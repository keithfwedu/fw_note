//
//  fw_noteApp.swift
//  fw_note
//
//  Created by Fung Wing on 31/3/2025.
//

import SwiftUI
import SwiftData

@main
struct fw_noteApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
       // FileHelper.ensureDirectoriesExist()

    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        
    }
}
