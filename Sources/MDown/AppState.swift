import MarkdownUI
import SwiftUI

final class AppState: ObservableObject {
    // MARK: - Constants

    static let fontSizeMin: CGFloat = 10
    static let fontSizeMax: CGFloat = 32
    static let fontSizeStep: CGFloat = 2
    static let fontSizeDefault: CGFloat = 16

    private static let themeKey = "selectedThemeID"
    private static let fontSizeKey = "baseFontSize"
    private static let fullWidthKey = "fullWidth"

    // MARK: - Published State

    @Published var markdownContent: String?
    @Published var currentFileURL: URL?
    @Published var baseFontSize: CGFloat {
        didSet { UserDefaults.standard.set(Double(baseFontSize), forKey: Self.fontSizeKey) }
    }
    @Published var selectedThemeID: String {
        didSet { UserDefaults.standard.set(selectedThemeID, forKey: Self.themeKey) }
    }
    @Published var fullWidth: Bool {
        didSet { UserDefaults.standard.set(fullWidth, forKey: Self.fullWidthKey) }
    }

    // MARK: - Computed

    var currentThemeDefinition: ThemeDefinition {
        ThemeDefinitions.all.first { $0.id == selectedThemeID }
            ?? ThemeDefinitions.defaultLight
    }

    var activeTheme: Theme {
        MDownTheme.build(from: currentThemeDefinition, fontSize: baseFontSize)
    }

    var windowBackground: Color {
        currentThemeDefinition.background
    }

    var windowTitle: String {
        if let url = currentFileURL {
            return url.lastPathComponent
        }
        return "MDown"
    }

    // MARK: - Init

    init() {
        let savedFontSize = UserDefaults.standard.double(forKey: Self.fontSizeKey)
        self.baseFontSize = savedFontSize > 0 ? CGFloat(savedFontSize) : Self.fontSizeDefault

        let savedTheme = UserDefaults.standard.string(forKey: Self.themeKey)
        self.selectedThemeID = savedTheme ?? ThemeDefinitions.defaultLight.id

        self.fullWidth = UserDefaults.standard.bool(forKey: Self.fullWidthKey)
    }

    // MARK: - Font Size

    func increaseFontSize() {
        baseFontSize = min(baseFontSize + Self.fontSizeStep, Self.fontSizeMax)
    }

    func decreaseFontSize() {
        baseFontSize = max(baseFontSize - Self.fontSizeStep, Self.fontSizeMin)
    }

    func resetFontSize() {
        baseFontSize = Self.fontSizeDefault
    }

    // MARK: - File Loading

    func loadFile(url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            markdownContent = content
            currentFileURL = url
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
        } catch {
            markdownContent = "**Error reading file:** \(error.localizedDescription)"
            currentFileURL = nil
        }
    }
}
