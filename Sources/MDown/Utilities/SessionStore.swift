import Foundation

/// Persists the set of files open across windows so they can be restored on
/// the next launch. Paths are stored in `UserDefaults`; the app is not
/// sandboxed, so plain paths (rather than security-scoped bookmarks) suffice.
final class SessionStore {
    static let shared = SessionStore()

    private let key = "openFilePaths"
    private let defaults = UserDefaults.standard

    /// Process-lifetime guard so restoration runs at most once, and is skipped
    /// when the app was launched by explicitly opening a file.
    var hasRestored = false

    private init() {}

    /// Currently-open files, in the order they were last opened.
    private var openURLs: [URL] {
        get {
            (defaults.array(forKey: key) as? [String])?
                .map { URL(fileURLWithPath: $0) } ?? []
        }
        set {
            defaults.set(newValue.map(\.path), forKey: key)
        }
    }

    /// Record a file as open (moves it to the end if already present).
    func record(_ url: URL) {
        var urls = openURLs
        urls.removeAll { $0.path == url.path }
        urls.append(url)
        openURLs = urls
    }

    /// Forget a file (called when its window is closed by the user).
    func remove(_ url: URL) {
        openURLs = openURLs.filter { $0.path != url.path }
    }

    /// Files to reopen on launch — those that still exist on disk.
    func restorableURLs() -> [URL] {
        let existing = openURLs.filter { FileManager.default.fileExists(atPath: $0.path) }
        // Prune entries whose files have since been deleted.
        if existing.count != openURLs.count {
            openURLs = existing
        }
        return existing
    }
}
