import Foundation

/// Hands files to windows that haven't been created yet. A window claims one
/// pending file in its `onAppear`. Backed by a FIFO queue so session
/// restoration can open several files across several new windows.
final class PendingFileManager {
    static let shared = PendingFileManager()
    private var queue: [URL] = []

    private init() {}

    /// Compatibility setter used by the File menu ("Open in New Window").
    var pendingURL: URL? {
        get { nil }
        set { if let newValue { queue.append(newValue) } }
    }

    func enqueue(_ url: URL) {
        queue.append(url)
    }

    func claimURL() -> URL? {
        queue.isEmpty ? nil : queue.removeFirst()
    }
}
