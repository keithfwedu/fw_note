import PDFKit
import SwiftUI

struct NoteExplorerView: View {
    //New Project
    @State private var pickMode = FilePickMode.file
    @State private var projectTitle: String = "Untitled"  // Default file name
    @State private var fileUrl: URL? = nil

    //Control
    @State private var isNewProjectPopoverPresented: Bool = false
    @State private var isFilePickerPresented: Bool = false
    @State private var isFileNameDialogPresented: Bool = false
    @State private var isLoading: Bool = false
    @State private var noteFiles: [NoteFile] = []
    let gridColumns = [GridItem(.adaptive(minimum: 150))]

    var body: some View {
        NavigationView {
            ZStack {
                VStack(alignment: .leading, spacing: 10) {
                    // Storage Usage Section
                    HStack(alignment: .bottom) {
                        StorageUsageView()
                        Spacer().frame(width: 16)
                        // "Add" Button
                        Button(action: {
                            isNewProjectPopoverPresented = true
                        }) {
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        .popover(isPresented: $isNewProjectPopoverPresented) {
                            VStack(spacing: 20) {
                                Button("Import File") {
                                    pickMode = FilePickMode.file
                                    isNewProjectPopoverPresented = false
                                    isFilePickerPresented = true
                                }
                                Button("Create Blank Project") {
                                    pickMode = FilePickMode.blank
                                    isNewProjectPopoverPresented = false
                                    isFileNameDialogPresented = true
                                    projectTitle = "Untitled"
                                    fileUrl = nil
                                }
                            }
                            .padding()
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
                                        destination: PdfNoteScreen(
                                            noteFile: noteFile
                                        )
                                    ) {

                                        NoteItemView(
                                            noteFile: noteFile,
                                        )
                                    }
                                    .withDeleteContextMenu(
                                        noteFile: noteFile,
                                        deleteAction: { noteFile in
                                            deleteNoteProject(
                                                noteFile: noteFile
                                            )
                                        }
                                    )
                                }
                            }
                        }
                    }

                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .fileImporter(
                    isPresented: $isFilePickerPresented,
                    allowedContentTypes: [.pdf],
                    allowsMultipleSelection: false
                ) { result in
                    handleFilePicked(result: result)
                }
                .alert(
                    "Enter File Name",
                    isPresented: $isFileNameDialogPresented,
                    actions: {
                        TextField("File Name", text: $projectTitle)
                        Button(
                            "Save",
                            action: {
                                createNewProject()
                            }
                        )
                        Button("Cancel", role: .cancel, action: {})
                    },
                    message: {
                        Text("Please input the name of the PDF file.")
                    }
                ).onAppear {
                    //print("onAppear")
                    noteFiles = FileHelper.listProjects()
                }

                // Transparent overlay
                if isLoading {
                    LoadingView()
                }

            }
        }

        .navigationTitle("Note Explorer")  // Ensure the title is visible
        .navigationBarTitleDisplayMode(.inline)  // Optional for a smaller title
        .navigationViewStyle(StackNavigationViewStyle())  // Force full-page layout, no sidebar

    }

    private func createNewProject() {
        isLoading = true
        FileHelper.createNewProject(
            pdfPathUrl: fileUrl,
            title: projectTitle
        )
        noteFiles = FileHelper.listProjects()
        isLoading = false
    }

    private func deleteNoteProject(noteFile: NoteFile) {
        isLoading = true
        FileHelper.deleteProject(projectId: noteFile.id.uuidString)
        noteFiles = FileHelper.listProjects()
        isLoading = false
    }

    // MARK: - Handle File Selection
    private func handleFilePicked(result: Result<[URL], Error>) {
        do {
            // Get the first file URL from the result
            guard let selectedFileURL = try result.get().first else {
                //print("No file was selected.")
                return
            }

            // Handle security-scoped resource if necessary
            let fileAccessed =
                selectedFileURL.startAccessingSecurityScopedResource()
            defer {
                if fileAccessed {
                    selectedFileURL.stopAccessingSecurityScopedResource()
                }
            }
            projectTitle =
                selectedFileURL.deletingPathExtension().lastPathComponent
            fileUrl = selectedFileURL
            isFileNameDialogPresented = true

        } catch let fileError as NSError {
            // Specific error handling with descriptive logging
            print(
                "Error handling file selection: \(fileError.localizedDescription)"
            )
            //print("Underlying error: \(fileError.userInfo)")
        } catch {
            // Catch any other unexpected errors
            //print("An unexpected error occurred: \(error)")
        }
    }

}
