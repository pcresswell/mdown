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
    @Published private(set) var contentChunks: [MarkdownChunk] = []
    @Published var currentFileURL: URL?
    @Published var baseFontSize: CGFloat {
        didSet {
            UserDefaults.standard.set(Double(baseFontSize), forKey: Self.fontSizeKey)
            rebuildTheme()
        }
    }
    @Published var selectedThemeID: String {
        didSet {
            UserDefaults.standard.set(selectedThemeID, forKey: Self.themeKey)
            rebuildTheme()
        }
    }
    @Published var fullWidth: Bool {
        didSet { UserDefaults.standard.set(fullWidth, forKey: Self.fullWidthKey) }
    }
    @Published private(set) var activeTheme: Theme

    // MARK: - Search State

    @Published var isSearching = false
    @Published var searchQuery = ""
    @Published var searchMatches: [SearchMatch] = []
    @Published var currentMatchIndex: Int = 0

    // MARK: - Computed

    var currentThemeDefinition: ThemeDefinition {
        ThemeDefinitions.all.first { $0.id == selectedThemeID }
            ?? ThemeDefinitions.defaultLight
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
        let fontSize = savedFontSize > 0 ? CGFloat(savedFontSize) : Self.fontSizeDefault
        self.baseFontSize = fontSize

        let savedTheme = UserDefaults.standard.string(forKey: Self.themeKey)
        let themeID = savedTheme ?? ThemeDefinitions.defaultLight.id
        self.selectedThemeID = themeID

        self.fullWidth = UserDefaults.standard.bool(forKey: Self.fullWidthKey)

        let def = ThemeDefinitions.all.first { $0.id == themeID } ?? ThemeDefinitions.defaultLight
        self.activeTheme = MDownTheme.build(from: def, fontSize: fontSize)
    }

    // MARK: - Search

    struct SearchMatch {
        let chunkIndex: Int
        let range: Range<String.Index>
    }

    func toggleSearch() {
        isSearching.toggle()
        if !isSearching {
            searchQuery = ""
            searchMatches = []
            currentMatchIndex = 0
        }
    }

    func performSearch() {
        guard !searchQuery.isEmpty else {
            searchMatches = []
            currentMatchIndex = 0
            return
        }

        var matches: [SearchMatch] = []
        let query = searchQuery.lowercased()

        for chunk in contentChunks {
            let lower = chunk.content.lowercased()
            var searchStart = lower.startIndex
            while let range = lower.range(of: query, range: searchStart..<lower.endIndex) {
                let originalRange = range.lowerBound..<range.upperBound
                matches.append(SearchMatch(chunkIndex: chunk.id, range: originalRange))
                searchStart = range.upperBound
            }
        }

        searchMatches = matches
        currentMatchIndex = matches.isEmpty ? 0 : 0
    }

    func nextMatch() {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + 1) % searchMatches.count
    }

    func previousMatch() {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex - 1 + searchMatches.count) % searchMatches.count
    }

    var currentMatchChunkID: Int? {
        guard !searchMatches.isEmpty else { return nil }
        return searchMatches[currentMatchIndex].chunkIndex
    }

    // MARK: - Theme

    private func rebuildTheme() {
        activeTheme = MDownTheme.build(from: currentThemeDefinition, fontSize: baseFontSize)
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

    // MARK: - Content

    private func setContent(_ content: String) {
        markdownContent = content
        contentChunks = MarkdownChunker.chunk(content)
    }

    // MARK: - File Watching

    private var fileWatcherSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1

    private func stopWatching() {
        fileWatcherSource?.cancel()
        fileWatcherSource = nil
        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }

    private func startWatching(url: URL) {
        stopWatching()

        fileDescriptor = Darwin.open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .attrib],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            guard let self, let currentURL = self.currentFileURL else { return }
            // Small delay to let the write finish
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.reloadFile()
                // Re-watch in case the file was replaced (editors often write to a temp then rename)
                self.startWatching(url: currentURL)
            }
        }

        source.setCancelHandler { [fd = fileDescriptor] in
            if fd >= 0 { Darwin.close(fd) }
        }
        // We'll manage close in cancel handler, so clear our tracking
        fileDescriptor = -1

        source.resume()
        fileWatcherSource = source
    }

    private func reloadFile() {
        guard let url = currentFileURL else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let chunks = MarkdownChunker.chunk(content)
                DispatchQueue.main.async {
                    guard let self else { return }
                    if content != self.markdownContent {
                        self.markdownContent = content
                        self.contentChunks = chunks
                    }
                }
            } catch {
                // File may be mid-write; ignore transient errors
            }
        }
    }

    // MARK: - File Loading

    func loadFile(url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            setContent(content)
            currentFileURL = url
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
            startWatching(url: url)
        } catch {
            setContent("**Error reading file:** \(error.localizedDescription)")
            currentFileURL = nil
            stopWatching()
        }
    }

    deinit {
        stopWatching()
    }
}
