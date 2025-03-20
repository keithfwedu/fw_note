import SwiftUI
class NavigationState: ObservableObject {
    @Published var isNavigationVisible: Bool = true
}

struct NoteExplorerView: View {
    @StateObject private var navigationState = NavigationState()
    @State private var noteFiles: [NoteFile] = [] // Store NoteFile objects
    let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    
    init() {
            // Load files immediately when the view is created
            _noteFiles = State(initialValue: listAllFiles())
        }
    
    var body: some View {
        VStack {
            NavigationView {
                VStack {
                    
                    if noteFiles.isEmpty {
                        // Display a message if there are no NoteFiles
                        Text("No Notes Found")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        // List all NoteFiles
                        List {
                            ForEach(noteFiles, id: \.id) { noteFile in
                                Text("\(noteFile.notePages.count)")
                                NavigationLink(
                                    destination: PdfNoteView(
                                        noteFile: noteFile,
                                        navigationState: navigationState
                                    )
                                ) {
                                    VStack(alignment: .leading) {
                                        Text(noteFile.title)
                                            .font(.headline)
                                        
                                        Text("ID: \(noteFile.id.uuidString)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        
                                        Text("PDF Path: \(noteFile.pdfFilePath ?? "Not Available")")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .onDelete(perform: deleteFile) // Enable swipe-to-delete
                        }
                    }
                    
                    // Button to create a new entry
                    Button(action: createNewEntry) {
                        Text("Add New Entry")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
                .navigationTitle("Note Explorer")
                .onDisappear() {
                    print("hide1");
                    navigationState.isNavigationVisible = false;
                }
                .onAppear() {
                    print("show1");
                    navigationState.isNavigationVisible = true;
                }
            }
            
            Text("\(navigationState.isNavigationVisible == true ? "1":"0")");
        }
    }

    // MARK: - Load Note Files
    private func loadFiles() {
        noteFiles = listAllFiles()
    }

    // MARK: - List All Files
    private func listAllFiles() -> [NoteFile] {
        let notesDirectory = appSupportDirectory.appendingPathComponent("fw_notes", isDirectory: true)
        var noteFiles: [NoteFile] = []
        let decoder = JSONDecoder()

        do {
            let subdirectories = try FileManager.default.contentsOfDirectory(at: notesDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            noteFiles = subdirectories.compactMap { directory in
                let jsonFileURL = directory.appendingPathComponent("data.json")
                guard FileManager.default.fileExists(atPath: jsonFileURL.path) else { return nil }

                do {
                    let data = try Data(contentsOf: jsonFileURL)
                    return try decoder.decode(NoteFile.self, from: data)
                } catch {
                    print("Error decoding JSON at \(jsonFileURL): \(error)")
                    return nil
                }
            }
        } catch {
            print("Error reading fw_notes directory: \(error)")
        }

        return noteFiles
    }

    // MARK: - Create New Entry
    private func createNewEntry() {
        do {
            // Step 1: Create a unique directory for the new NoteFile
            let uniqueID = UUID().uuidString
            let relativeDirectoryPath = "fw_notes/\(uniqueID)"
            let uniqueDirectory = appSupportDirectory.appendingPathComponent(relativeDirectoryPath, isDirectory: true)
            try FileManager.default.createDirectory(at: uniqueDirectory, withIntermediateDirectories: true, attributes: nil)

            // Step 2: Locate example.pdf in the app bundle
            guard let examplePDF = Bundle.main.url(forResource: "example", withExtension: "pdf") else {
                print("example.pdf not found in bundle")
                return
            }

            // Step 3: Copy the example.pdf to the unique directory
            let pdfFileName = "example.pdf"
            let pdfFileURL = uniqueDirectory.appendingPathComponent(pdfFileName)
            try FileManager.default.copyItem(at: examplePDF, to: pdfFileURL)
            print("Copied example.pdf to \(pdfFileURL)")
            
            

            // Step 4: Create a new NoteFile with relative pdfFilePath
            let newNoteFile = NoteFile(
                title: "New Note \(Date().description)",
                pdfFilePath: "\(relativeDirectoryPath)/\(pdfFileName)"
            )
            
         

            // Step 5: Save the NoteFile to data.json in the unique directory
            let jsonFileURL = uniqueDirectory.appendingPathComponent("data.json")
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(newNoteFile)
            try jsonData.write(to: jsonFileURL)
            print("Saved new NoteFile as data.json at \(jsonFileURL)")

            // Step 6: Refresh the list of NoteFiles
            loadFiles()

        } catch {
            print("Error creating new entry: \(error)")
        }
    }

  
    // MARK: - Delete a NoteFile
    private func deleteFile(at offsets: IndexSet) {
        offsets.forEach { index in
            let noteFile = noteFiles[index]
            
            // Dynamically resolve the absolute path for the note's directory using the relative path
            if let relativePdfPath = noteFile.pdfFilePath {
                let absolutePdfPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                    .first!.appendingPathComponent(relativePdfPath).deletingLastPathComponent() // Get directory path
                
                // Ensure the directory exists before attempting deletion
                guard FileManager.default.fileExists(atPath: absolutePdfPath.path) else {
                    print("Directory not found: \(absolutePdfPath.path)")
                    return
                }
                
                do {
                    // Remove the directory and its contents
                    try FileManager.default.removeItem(at: absolutePdfPath)
                    print("Deleted note at: \(absolutePdfPath.path)")
                } catch {
                    print("Error deleting note at \(absolutePdfPath.path): \(error)")
                }
            } else {
                print("No valid pdfFilePath found for note: \(noteFile.title)")
            }
        }
        
        // Refresh the list
        loadFiles()
    }


}
