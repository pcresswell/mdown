import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var appState: AppState

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Themes")
                .font(.headline)
                .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(ThemeDefinitions.all) { theme in
                    ThemeCard(
                        theme: theme,
                        isSelected: theme.id == appState.selectedThemeID
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            appState.selectedThemeID = theme.id
                        }
                    }
                }
            }

            Divider()

            HStack {
                Text("Font Size: \(Int(appState.baseFontSize))pt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Spacer()

                Button(action: { appState.decreaseFontSize() }) {
                    Image(systemName: "minus")
                }
                .buttonStyle(.borderless)
                .disabled(appState.baseFontSize <= AppState.fontSizeMin)

                Button(action: { appState.resetFontSize() }) {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.borderless)

                Button(action: { appState.increaseFontSize() }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .disabled(appState.baseFontSize >= AppState.fontSizeMax)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Density")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(action: { appState.resetDensity() }) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .buttonStyle(.borderless)
                    .help("Reset to this theme's default")
                }

                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.and.down.text.horizontal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .help("More compressed")
                    // Slider runs spacious → compressed left-to-right, so the
                    // value is inverted: dragging right tightens the layout.
                    Slider(
                        value: Binding(
                            get: { AppState.densityMax - (appState.density - AppState.densityMin) },
                            set: { appState.density = AppState.densityMax - ($0 - AppState.densityMin) }
                        ),
                        in: AppState.densityMin...AppState.densityMax
                    )
                    Image(systemName: "arrow.down.and.line.horizontal.and.arrow.up")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .help("Less compressed")
                }
                HStack {
                    Text("Spacious")
                    Spacer()
                    Text("Compact")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(width: 280)
    }
}

struct ThemeCard: View {
    let theme: ThemeDefinition
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            // Color swatches
            HStack(spacing: 0) {
                ForEach(Array(theme.swatchColors.enumerated()), id: \.offset) { _, color in
                    color.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(theme.name)
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isSelected ? Color.accentColor : Color.clear,
                    lineWidth: 2
                )
        )
        .contentShape(Rectangle())
    }
}
