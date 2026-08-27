import AppKit

/// Mirrors `NSDocumentController`'s recent-documents list into an
/// `ObservableObject` so the File > Open Recent command menu updates live.
///
/// `NSDocumentController.shared` is the single source of truth for recent
/// files (see `AppState.loadFile`, which calls `noteNewRecentDocumentURL`).
/// This class does not keep a parallel store — it only republishes that same
/// list so SwiftUI's `.commands` scene, which does not reliably re-evaluate
/// on its own, refreshes when a new file is opened.
final class RecentDocuments: ObservableObject {
    static let shared = RecentDocuments()
    static let maxCount = 10

    @Published private(set) var urls: [URL] = []

    private init() {
        refresh()
    }

    /// Re-reads the list from `NSDocumentController`. Call after any change
    /// (a file opened, or the user cleared the menu).
    func refresh() {
        urls = Array(NSDocumentController.shared.recentDocumentURLs.prefix(Self.maxCount))
    }

    func clear() {
        NSDocumentController.shared.clearRecentDocuments(nil)
        refresh()
    }
}
