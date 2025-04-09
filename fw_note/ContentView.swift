import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: AppState.entity(),
        sortDescriptors: []
    ) private var appState: FetchedResults<AppState>
    
    var body: some View {
        NoteExplorerView()
            .onAppear {
                if appState.first == nil {
                    createDefaultAppState()
                }
            }
    }
    
    // Function to create a default AppState if none exists
    private func createDefaultAppState() {
        let newAppState = AppState(context: viewContext)
        newAppState.currentUserId = "guest"
        do {
            try viewContext.save()
            print("Default AppState created!")
        } catch {
            print("Failed to save default AppState: \(error)")
        }
    }
}
