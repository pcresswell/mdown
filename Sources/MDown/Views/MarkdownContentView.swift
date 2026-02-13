import MarkdownUI
import SwiftUI

struct MarkdownContentView: View {
    @EnvironmentObject private var appState: AppState
    let content: String

    var body: some View {
        ScrollView {
            Markdown(content)
                .markdownTheme(appState.activeTheme)
                .textSelection(.enabled)
                .padding(.horizontal, appState.fullWidth ? 16 : 40)
                .padding(.vertical, appState.fullWidth ? 16 : 32)
                .frame(maxWidth: appState.fullWidth ? .infinity : 800, alignment: .leading)
                .frame(maxWidth: .infinity)
        }
    }
}
