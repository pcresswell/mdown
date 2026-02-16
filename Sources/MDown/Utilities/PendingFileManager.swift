import Foundation

final class PendingFileManager {
    static let shared = PendingFileManager()
    var pendingURL: URL?

    private init() {}

    func claimURL() -> URL? {
        let url = pendingURL
        pendingURL = nil
        return url
    }
}
