import SwiftUI

@main
struct MDownApp: App {
    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                FileMenuCommands()
            }

            CommandGroup(after: .textEditing) {
                FindMenuCommands()
            }

            CommandMenu("Display") {
                DisplayMenuCommands()
            }
        }
    }
}

struct FileMenuCommands: View {
    @FocusedObject private var appState: AppState?
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open...") {
            FileService.openFile { url in
                if let url {
                    if let appState {
                        appState.loadFile(url: url)
                    } else {
                        PendingFileManager.shared.pendingURL = url
                        openWindow(id: "main")
                    }
                }
            }
        }
        .keyboardShortcut("o", modifiers: .command)

        Button("Open in New Window...") {
            FileService.openFile { url in
                if let url {
                    PendingFileManager.shared.pendingURL = url
                    openWindow(id: "main")
                }
            }
        }
        .keyboardShortcut("o", modifiers: [.command, .shift])
    }
}

struct FindMenuCommands: View {
    @FocusedObject private var appState: AppState?

    var body: some View {
        Button("Find...") {
            postFindAction(tag: 1)
        }
        .keyboardShortcut("f", modifiers: .command)
        .disabled(appState?.markdownContent == nil)

        Button("Find Next") {
            postFindAction(tag: 2)
        }
        .keyboardShortcut("g", modifiers: .command)
        .disabled(appState?.markdownContent == nil)

        Button("Find Previous") {
            postFindAction(tag: 3)
        }
        .keyboardShortcut("g", modifiers: [.command, .shift])
        .disabled(appState?.markdownContent == nil)
    }

    private func postFindAction(tag: Int) {
        NotificationCenter.default.post(
            name: .mdownPerformFindAction,
            object: nil,
            userInfo: ["tag": tag]
        )
    }
}

struct DisplayMenuCommands: View {
    @FocusedObject private var appState: AppState?

    var body: some View {
        Button(appState?.fullWidth == true ? "Half Width" : "Full Width") {
            withAnimation(.easeInOut(duration: 0.2)) {
                appState?.fullWidth.toggle()
            }
        }
        .keyboardShortcut("\\", modifiers: .command)
        .disabled(appState == nil)

        Divider()

        Button("Increase Font Size") {
            appState?.increaseFontSize()
        }
        .keyboardShortcut("=", modifiers: .command)
        .disabled(appState == nil)

        Button("Decrease Font Size") {
            appState?.decreaseFontSize()
        }
        .keyboardShortcut("-", modifiers: .command)
        .disabled(appState == nil)

        Button("Reset Font Size") {
            appState?.resetFontSize()
        }
        .keyboardShortcut("0", modifiers: .command)
        .disabled(appState == nil)
    }
}
