//
//  fw_noteApp.swift
//  fw_note
//
//  Created by Fung Wing on 31/3/2025.
//

import SwiftUI
import SwiftData

var currentProjectId: UUID? = nil

@main
struct fw_noteApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
       FileHelper.ensureProjectDirectoriesExist()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        
    }
}
