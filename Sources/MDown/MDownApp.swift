import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// True once the app has begun terminating, so windows tearing down on
    /// quit don't erase the restorable session.
    static var isTerminating = false

    func applicationWillTerminate(_ notification: Notification) {
        AppDelegate.isTerminating = true
    }
}

@main
struct MDownApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

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
    @ObservedObject private var recentDocuments = RecentDocuments.shared

    var body: some View {
        Button("Open...") {
            FileService.openFile { url in
                if let url {
                    openInCurrentContext(url)
                }
            }
        }
        .keyboardShortcut("o", modifiers: .command)

        Menu("Open Recent") {
            ForEach(recentDocuments.urls, id: \.self) { url in
                Button(url.lastPathComponent) {
                    openInCurrentContext(url)
                }
            }

            Divider()

            Button("Clear Menu") {
                recentDocuments.clear()
            }
            .disabled(recentDocuments.urls.isEmpty)
        }

        Button("Open in New Window...") {
            FileService.openFile { url in
                if let url {
                    PendingFileManager.shared.pendingURL = url
                    openWindow(id: "main")
                }
            }
        }
        .keyboardShortcut("o", modifiers: [.command, .shift])

        Divider()

        Button("Print...") {
            guard let appState, let markdown = appState.markdownContent else { return }
            PrintService.print(
                markdown: markdown,
                fileURL: appState.currentFileURL,
                fontSize: appState.baseFontSize
            )
        }
        .keyboardShortcut("p", modifiers: .command)
        .disabled(appState?.markdownContent == nil)
    }

    /// Opens a file the same way "Open..." does: into the focused window if
    /// there is one, otherwise into a newly created window. Used by both the
    /// Open panel and Open Recent entries so behavior stays identical.
    private func openInCurrentContext(_ url: URL) {
        if let appState {
            appState.loadFile(url: url)
        } else {
            PendingFileManager.shared.pendingURL = url
            openWindow(id: "main")
        }
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
