import MarkdownUI
import SwiftUI

struct MarkdownContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(appState.contentChunks) { chunk in
                    Markdown(chunk.content)
                        .markdownTheme(appState.activeTheme)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, appState.fullWidth ? 16 : 40)
            .padding(.vertical, appState.fullWidth ? 16 : 32)
            .frame(maxWidth: appState.fullWidth ? .infinity : 800, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }
}
