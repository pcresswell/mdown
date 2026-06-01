import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    @State private var showThemePicker = false
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            if let content = appState.markdownContent {
                SearchableMarkdownView(
                    markdown: content,
                    theme: appState.currentThemeDefinition,
                    fontSize: appState.baseFontSize,
                    density: appState.density,
                    fullWidth: appState.fullWidth
                )
            } else {
                WelcomeView()
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(appState.windowBackground)
        .onDrop(of: [.fileURL], delegate: MarkdownDropDelegate(appState: appState))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showThemePicker.toggle()
                } label: {
                    Image(systemName: "paintpalette")
                }
                .help("Themes & Font Size")
                .popover(isPresented: $showThemePicker, arrowEdge: .bottom) {
                    ThemePickerView()
                        .environmentObject(appState)
                }
            }
        }
        .navigationTitle(appState.windowTitle)
        .environmentObject(appState)
        .focusedObject(appState)
        .onOpenURL { url in
            // Launched/activated by opening a specific file — don't also
            // restore the previous session on top of it.
            SessionStore.shared.hasRestored = true
            appState.loadFile(url: url)
            NSApp.activate(ignoringOtherApps: true)
        }
        .onAppear {
            if let url = PendingFileManager.shared.claimURL() {
                appState.loadFile(url: url)
            } else if !SessionStore.shared.hasRestored {
                SessionStore.shared.hasRestored = true
                let urls = SessionStore.shared.restorableURLs()
                // Defer one runloop so an `onOpenURL` launch wins the race.
                DispatchQueue.main.async {
                    guard appState.currentFileURL == nil, let first = urls.first else { return }
                    appState.loadFile(url: first)
                    for extra in urls.dropFirst() {
                        PendingFileManager.shared.enqueue(extra)
                        openWindow(id: "main")
                    }
                }
            }
        }
    }
}
