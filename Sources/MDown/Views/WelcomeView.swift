import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "doc.richtext")
                .font(.system(size: 64))
                .foregroundStyle(appState.currentThemeDefinition.text.opacity(0.4))

            Text("MDown")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .foregroundStyle(appState.currentThemeDefinition.headingColor)

            Text("Open or drop a Markdown file to get started")
                .font(.title3)
                .foregroundStyle(appState.currentThemeDefinition.text.opacity(0.7))

            Button("Open File...") {
                FileService.openFile { url in
                    if let url {
                        appState.loadFile(url: url)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)

            Spacer()

            Text("Drag & drop .md files here")
                .font(.caption)
                .foregroundStyle(appState.currentThemeDefinition.text.opacity(0.4))
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
