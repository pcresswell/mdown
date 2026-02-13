import SwiftUI

@main
struct MDownApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .commands {
            // File menu: Open
            CommandGroup(after: .newItem) {
                Button("Open...") {
                    FileService.openFile { url in
                        if let url {
                            appState.loadFile(url: url)
                        }
                    }
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            // Display menu: layout + font size
            CommandMenu("Display") {
                Button(appState.fullWidth ? "Half Width" : "Full Width") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.fullWidth.toggle()
                    }
                }
                .keyboardShortcut("\\", modifiers: .command)

                Divider()

                Button("Increase Font Size") {
                    appState.increaseFontSize()
                }
                .keyboardShortcut("=", modifiers: .command)

                Button("Decrease Font Size") {
                    appState.decreaseFontSize()
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("Reset Font Size") {
                    appState.resetFontSize()
                }
                .keyboardShortcut("0", modifiers: .command)
            }
        }
    }
}
