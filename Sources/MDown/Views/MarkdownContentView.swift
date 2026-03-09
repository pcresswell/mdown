import MarkdownUI
import SwiftUI

struct MarkdownContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(appState.contentChunks) { chunk in
                        Markdown(chunk.content)
                            .markdownTheme(appState.activeTheme)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(chunk.id)
                            .background(
                                chunk.id == appState.currentMatchChunkID
                                    ? appState.currentThemeDefinition.linkColor.opacity(0.1)
                                    : Color.clear
                            )
                    }
                }
                .padding(.horizontal, appState.fullWidth ? 16 : 40)
                .padding(.vertical, appState.fullWidth ? 16 : 32)
                .frame(maxWidth: appState.fullWidth ? .infinity : 800, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: appState.currentMatchIndex) { _ in
                scrollToMatch(proxy: proxy)
            }
            .onChange(of: appState.searchMatches.count) { _ in
                scrollToMatch(proxy: proxy)
            }
        }
    }

    private func scrollToMatch(proxy: ScrollViewProxy) {
        guard let chunkID = appState.currentMatchChunkID else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            proxy.scrollTo(chunkID, anchor: .center)
        }
    }
}
