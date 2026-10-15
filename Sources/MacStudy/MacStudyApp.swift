import SwiftUI

@main struct ShilgaraApp: App {
    @StateObject private var store = AcademicStore()

    var body: some Scene {
        WindowGroup {
            LaunchIntroView()
                .environmentObject(store)
                .background(WindowSizingView())
                .alert("Storage issue", isPresented: Binding(
                    get: { store.storageError != nil },
                    set: { if !$0 { store.storageError = nil } }
                )) {
                    Button("OK") { store.storageError = nil }
                } message: {
                    Text(store.storageError ?? "")
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.automatic)
        .defaultSize(width: 1080, height: 680)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Data") {
                Button("Export Backup…") { store.exportBackup() }
                Button("Import Backup…") { store.importBackup() }
            }
        }
    }
}
