import AppKit

/// Print pipeline: re-renders the markdown into a fresh light-themed
/// NSAttributedString (with mermaid diagrams already rasterized to PNGs by
/// MarkdownRenderer's async path), wraps it in a paginating NSTextView sized
/// to a US Letter content area, and hands it to NSPrintOperation.
enum PrintService {

    @MainActor
    static func print(markdown: String, fileURL: URL?, fontSize: CGFloat) {
        guard !markdown.isEmpty else {
            NSSound.beep()
            return
        }

        Task { @MainActor in
            let theme = ThemeDefinitions.defaultLight
            let attrString = await MarkdownRenderer.render(
                markdown: markdown, theme: theme, fontSize: fontSize
            )

            let printInfo = NSPrintInfo.shared.copy() as? NSPrintInfo ?? NSPrintInfo()
            // ~0.75" margins.
            printInfo.topMargin = 54
            printInfo.bottomMargin = 54
            printInfo.leftMargin = 54
            printInfo.rightMargin = 54
            printInfo.horizontalPagination = .fit
            printInfo.verticalPagination = .automatic

            let paperSize = printInfo.paperSize
            let contentWidth = paperSize.width
                - printInfo.leftMargin - printInfo.rightMargin

            let container = NSTextContainer(
                size: NSSize(width: contentWidth, height: .greatestFiniteMagnitude)
            )
            container.lineFragmentPadding = 0
            container.widthTracksTextView = false

            let layoutManager = NSLayoutManager()
            layoutManager.addTextContainer(container)

            let storage = NSTextStorage(attributedString: attrString)
            storage.addLayoutManager(layoutManager)

            let textView = NSTextView(
                frame: NSRect(origin: .zero, size: NSSize(width: contentWidth, height: 100)),
                textContainer: container
            )
            textView.isEditable = false
            textView.isSelectable = false
            textView.drawsBackground = true
            textView.backgroundColor = NSColor(theme.background)
            textView.textContainerInset = .zero
            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            textView.autoresizingMask = []

            // Force layout so we know the document's full height.
            layoutManager.ensureLayout(for: container)
            let used = layoutManager.usedRect(for: container)
            textView.frame = NSRect(
                x: 0, y: 0,
                width: contentWidth,
                height: max(used.height, 100)
            )

            let operation = NSPrintOperation(view: textView, printInfo: printInfo)
            operation.jobTitle = fileURL?.deletingPathExtension().lastPathComponent ?? "MDown Document"
            operation.showsPrintPanel = true
            operation.showsProgressPanel = true
            operation.run()
        }
    }
}
