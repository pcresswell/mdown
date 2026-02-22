import Foundation

struct MarkdownChunk: Identifiable {
    let id: Int
    let content: String
}

enum MarkdownChunker {
    /// Documents smaller than this are returned as a single chunk
    private static let chunkThreshold = 3000

    static func chunk(_ markdown: String) -> [MarkdownChunk] {
        guard markdown.count > chunkThreshold else {
            return [MarkdownChunk(id: 0, content: markdown)]
        }

        var chunks: [MarkdownChunk] = []
        var currentLines: [String] = []
        var currentSize = 0
        var inCodeFence = false
        var chunkIndex = 0

        for line in markdown.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                inCodeFence.toggle()
            }

            currentLines.append(line)
            currentSize += line.count + 1

            // Split at blank lines when outside code fences and over threshold
            if !inCodeFence && currentSize >= chunkThreshold && trimmed.isEmpty {
                let text = currentLines.joined(separator: "\n")
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    chunks.append(MarkdownChunk(id: chunkIndex, content: text))
                    chunkIndex += 1
                }
                currentLines = []
                currentSize = 0
            }
        }

        if !currentLines.isEmpty {
            let text = currentLines.joined(separator: "\n")
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                chunks.append(MarkdownChunk(id: chunkIndex, content: text))
            }
        }

        return chunks.isEmpty ? [MarkdownChunk(id: 0, content: markdown)] : chunks
    }
}
