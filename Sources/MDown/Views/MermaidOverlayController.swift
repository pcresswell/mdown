import AppKit

/// Places a zoomable NSScrollView on top of every mermaid PNG attachment in
/// the text view. Pinch/scroll inside the frame magnifies the image; the
/// frames scroll with the document because they're subviews of the text view.
@MainActor
final class MermaidOverlayController {
    weak var textView: NSTextView?

    private struct Entry {
        let range: NSRange
        let view: MermaidFrameView
    }
    private var entries: [Entry] = []

    /// Rebuild overlays for the text view's current content.
    func rebuild() {
        clear()
        guard
            let textView,
            let textStorage = textView.textStorage,
            let layoutManager = textView.layoutManager,
            let container = textView.textContainer
        else { return }

        // Force layout so boundingRect queries return real values.
        layoutManager.ensureLayout(for: container)

        let full = NSRange(location: 0, length: textStorage.length)
        textStorage.enumerateAttribute(.attachment, in: full, options: []) { value, range, _ in
            guard let attachment = value as? NSTextAttachment,
                  let url = mermaidImageURL(for: attachment),
                  let image = NSImage(contentsOf: url)
            else { return }

            let frame = MermaidFrameView(image: image)
            textView.addSubview(frame)
            entries.append(Entry(range: range, view: frame))
        }

        updatePositions()
    }

    /// Re-query attachment rects and re-place each overlay. Call after layout
    /// may have shifted (window resize, text container inset change, etc.).
    func updatePositions() {
        guard
            let textView,
            let layoutManager = textView.layoutManager,
            let container = textView.textContainer
        else { return }

        let inset = textView.textContainerInset
        for entry in entries {
            let glyphRange = layoutManager.glyphRange(
                forCharacterRange: entry.range, actualCharacterRange: nil
            )
            let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: container)
            entry.view.frame = NSRect(
                x: rect.origin.x + inset.width,
                y: rect.origin.y + inset.height,
                width: rect.width,
                height: rect.height
            )
            entry.view.resetMagnificationToFit()
        }
    }

    func clear() {
        for entry in entries {
            entry.view.removeFromSuperview()
        }
        entries.removeAll()
    }

    /// If the attachment came from our mermaid renderer, return the PNG URL on
    /// disk. We identify them by the "-w900.png" suffix of our cache key.
    private func mermaidImageURL(for attachment: NSTextAttachment) -> URL? {
        let filename =
            attachment.fileWrapper?.preferredFilename
            ?? attachment.fileWrapper?.filename
            ?? ""
        guard filename.hasSuffix(".png"), filename.contains("-w900") else { return nil }
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(
            "mdown-mermaid", isDirectory: true
        )
        let candidate = dir.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: candidate.path) ? candidate : nil
    }
}

/// A fixed-size viewport showing a mermaid image. Trackpad pinch magnifies,
/// two-finger scroll pans, and click-and-drag pans when magnified.
final class MermaidFrameView: NSScrollView {
    private let imageView: NSImageView
    private let image: NSImage

    init(image: NSImage) {
        self.image = image
        self.imageView = NSImageView()
        super.init(frame: .zero)

        hasVerticalScroller = true
        hasHorizontalScroller = true
        autohidesScrollers = true
        allowsMagnification = true
        minMagnification = 0.25
        maxMagnification = 8.0
        drawsBackground = false
        borderType = .lineBorder
        scrollerStyle = .overlay

        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.frame = NSRect(origin: .zero, size: image.size)
        documentView = imageView

        // A two-finger drag inside the frame should pan, not bubble out to
        // the text view's scroll. We stop vertical wheel events that would
        // otherwise scroll the document instead of the image.
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func scrollWheel(with event: NSEvent) {
        // Only capture the event if the user is magnifying (cmd+scroll) or
        // has scrolled the image within the frame. Otherwise let the outer
        // document scroll through so normal page scrolling still works.
        if event.modifierFlags.contains(.command) || magnification > 1.001 {
            super.scrollWheel(with: event)
        } else {
            nextResponder?.scrollWheel(with: event)
        }
    }

    /// Size the image to fit the current viewport, preserving aspect.
    func resetMagnificationToFit() {
        guard image.size.width > 0, image.size.height > 0 else { return }
        let viewport = bounds.size
        guard viewport.width > 0, viewport.height > 0 else { return }

        // Keep the imageView at natural image size; use magnification to fit.
        imageView.frame = NSRect(origin: .zero, size: image.size)
        let fitScale = min(
            viewport.width / image.size.width,
            viewport.height / image.size.height
        )
        magnification = max(minMagnification, min(maxMagnification, fitScale))
    }
}
