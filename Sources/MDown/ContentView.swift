import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    @State private var showThemePicker = false

    var body: some View {
        Group {
            if let content = appState.markdownContent {
                MarkdownContentView(content: content)
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
            appState.loadFile(url: url)
            NSApp.activate(ignoringOtherApps: true)
        }
        .onAppear {
            if let url = PendingFileManager.shared.claimURL() {
                appState.loadFile(url: url)
            }
        }
    }
}
