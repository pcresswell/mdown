import SwiftUI

struct SearchBarView: View {
    @EnvironmentObject private var appState: AppState
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search...", text: $appState.searchQuery)
                .textFieldStyle(.plain)
                .focused($isFieldFocused)
                .onChange(of: appState.searchQuery) { _ in
                    appState.performSearch()
                }
                .onSubmit {
                    if NSApp.currentEvent?.modifierFlags.contains(.shift) == true {
                        appState.previousMatch()
                    } else {
                        appState.nextMatch()
                    }
                }
                .onExitCommand {
                    appState.toggleSearch()
                }

            if !appState.searchQuery.isEmpty {
                Text(matchLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()

                Button(action: { appState.previousMatch() }) {
                    Image(systemName: "chevron.up")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .disabled(appState.searchMatches.isEmpty)

                Button(action: { appState.nextMatch() }) {
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .disabled(appState.searchMatches.isEmpty)
            }

            Button(action: { appState.toggleSearch() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        .padding(.horizontal, 16)
        .onAppear {
            isFieldFocused = true
        }
    }

    private var matchLabel: String {
        if appState.searchMatches.isEmpty {
            return "No matches"
        }
        return "\(appState.currentMatchIndex + 1) of \(appState.searchMatches.count)"
    }
}
