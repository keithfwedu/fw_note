import SwiftUI
import PDFKit

struct NoteExplorerView: View {
    @State private var userId: String = "guest"
    @State private var noteFiles: [NoteFile] = []
    @State private var isFilePickerPresented: Bool = false
    @State private var freeSpaceRatio: Double = 0.0
    let appSupportDirectory = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask
    ).first!
    let gridColumns = [GridItem(.adaptive(minimum: 150))]

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 10) {
                // Storage Usage Section
                HStack(alignment: .bottom) {
                    StorageUsageView(freeSpaceRatio: freeSpaceRatio)
                    Spacer()
                    // "Add" Button
                    Button(action: {
                        isFilePickerPresented = true
                    }) {
                        Image(systemName: "plus")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                }
                .frame(height: 50)
                .padding(.all, 8)

                // Notes Grid Section
                if noteFiles.isEmpty {
                    VStack {
                        Text("No Notes Found")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding()
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                    noteFile: noteFile, deleteAction: { noteFile in
                                        deleteNoteProject(userId: userId, noteFile: noteFile)
                                    }
                                )
                            }
                        }
                    }
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
                addFileToProject(userId: userId,result: result)
            }
            .onAppear {
                updateFreeSpace()
                noteFiles = FileHelper.listProjects()
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

   
    private func deleteNoteProject(userId: String, noteFile: NoteFile) {
        FileHelper.deleteProject(projectId: noteFile.id.uuidString)
        noteFiles = FileHelper.listProjects()
    }

    // MARK: - Handle File Selection
    private func addFileToProject(userId:String, result: Result<[URL], Error>) {
        do {
            // Get the first file URL from the result
            guard let selectedFileURL = try result.get().first else {
                print("No file was selected.")
                return
            }

            // Handle security-scoped resource if necessary
            let fileAccessed = selectedFileURL.startAccessingSecurityScopedResource()
            defer { if fileAccessed { selectedFileURL.stopAccessingSecurityScopedResource() } }
            
            FileHelper.createNewProject(pdfPathUrl: selectedFileURL)
            // Update the list of notes
            noteFiles = FileHelper.listProjects()

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
