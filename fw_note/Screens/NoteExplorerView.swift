import SwiftUI
import PDFKit

struct NoteExplorerView: View {
    @State private var noteFiles: [NoteFile] = []
    @State private var isFilePickerPresented: Bool = false
    @State private var freeSpaceRatio: Double = 0.0
    let appSupportDirectory = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask
    ).first!
    let gridColumns = [GridItem(.adaptive(minimum: 150))]

    var body: some View {
        NavigationView {
            VStack {
                // Storage Usage Section
                StorageUsageView(freeSpaceRatio: freeSpaceRatio)

                // Notes Grid Section
                if noteFiles.isEmpty {
                    Text("No Notes Found")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: gridColumns, spacing: 20) {
                            ForEach(noteFiles, id: \.id) { noteFile in
                                NavigationLink(
                                    destination: PdfNoteScreen(noteFile: noteFile)
                                ) {
                                    NoteItemView(
                                        noteFile: noteFile,
                                        appSupportDirectory: appSupportDirectory
                                    )
                                }
                                .withDeleteContextMenu(
                                    noteFile: noteFile, deleteAction: deleteFile
                                )
                            }
                        }
                    }
                }

                // "Add" Button
                Button(action: {
                    isFilePickerPresented = true
                }) {
                    Image(systemName: "plus")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            .padding()
            .navigationTitle("Note Explorer") // Ensure the title is visible
            .navigationBarTitleDisplayMode(.inline) // Optional for a smaller title
            .navigationViewStyle(StackNavigationViewStyle()) // Force full-page layout, no sidebar
            .fileImporter(
                isPresented: $isFilePickerPresented,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result: result)
            }
            .onAppear {
                updateFreeSpace()
                noteFiles = listAllFiles() // Load files lazily
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensure it works even on iPad
    }

    // MARK: - Update Free Space
    private func updateFreeSpace() {
        if let attributes = try? FileManager.default.attributesOfFileSystem(
            forPath: NSHomeDirectory()),
            let freeSpace = attributes[.systemFreeSize] as? Double,
            let totalSpace = attributes[.systemSize] as? Double
        {
            freeSpaceRatio = freeSpace / totalSpace
        }
    }

    // MARK: - List All Files
    private func listAllFiles() -> [NoteFile] {
        let notesDirectory = appSupportDirectory.appendingPathComponent(
            "fw_notes", isDirectory: true)
        var noteFiles: [NoteFile] = []
        let decoder = JSONDecoder()

        do {
            let subdirectories = try FileManager.default.contentsOfDirectory(
                at: notesDirectory, includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles)
            noteFiles = subdirectories.compactMap { directory in
                let jsonFileURL = directory.appendingPathComponent("data.json")
                guard FileManager.default.fileExists(atPath: jsonFileURL.path)
                else { return nil }

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

    // MARK: - Delete a NoteFile
    private func deleteFile(noteFile: NoteFile) {
        if let relativePdfPath = noteFile.pdfFilePath {
            let absolutePdfPath = appSupportDirectory.appendingPathComponent(relativePdfPath).deletingLastPathComponent()

            guard FileManager.default.fileExists(atPath: absolutePdfPath.path) else {
                print("Directory not found: \(absolutePdfPath.path)")
                return
            }

            do {
                try FileManager.default.removeItem(at: absolutePdfPath)
            } catch {
                print("Error deleting note at \(absolutePdfPath.path): \(error)")
            }
        }

        noteFiles = listAllFiles()
    }

    // MARK: - Handle File Selection
    private func handleFileSelection(result: Result<[URL], Error>) {
        do {
            // Get the first file URL from the result
            guard let selectedFileURL = try result.get().first else {
                print("No file was selected.")
                return
            }

            // Handle security-scoped resource if necessary
            let fileAccessed = selectedFileURL.startAccessingSecurityScopedResource()
            defer { if fileAccessed { selectedFileURL.stopAccessingSecurityScopedResource() } }

            // Generate a unique directory path for the note
            let uniqueID = UUID().uuidString
            let relativeDirectoryPath = "fw_notes/\(uniqueID)"
            let uniqueDirectory = appSupportDirectory.appendingPathComponent(relativeDirectoryPath, isDirectory: true)

            // Create the directory, ensuring intermediate directories are created
            try FileManager.default.createDirectory(at: uniqueDirectory, withIntermediateDirectories: true, attributes: nil)
            print("Directory created at: \(uniqueDirectory)")

            // Copy the selected file to the new directory
            let pdfFileName = selectedFileURL.lastPathComponent
            let pdfFileURL = uniqueDirectory.appendingPathComponent(pdfFileName)
            try FileManager.default.copyItem(at: selectedFileURL, to: pdfFileURL)
            print("File copied to: \(pdfFileURL)")

            // Create the NoteFile object
            let newNoteFile = NoteFile(
                title: "New Note \(Date().description)", // Generate a unique title
                pdfFilePath: "\(relativeDirectoryPath)/\(pdfFileName)"
            )

            // Save metadata as a JSON file
            let jsonFileURL = uniqueDirectory.appendingPathComponent("data.json")
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(newNoteFile)
            try jsonData.write(to: jsonFileURL)
            print("Metadata saved to: \(jsonFileURL)")

            // Update the list of notes
            noteFiles = listAllFiles()

        } catch let fileError as NSError {
            // Specific error handling with descriptive logging
            print("Error handling file selection: \(fileError.localizedDescription)")
            print("Underlying error: \(fileError.userInfo)")
        } catch {
            // Catch any other unexpected errors
            print("An unexpected error occurred: \(error)")
        }
    }


}
