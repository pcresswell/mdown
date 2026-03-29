import AppKit
import SwiftUI

extension Notification.Name {
    static let mdownPerformFindAction = Notification.Name("mdownPerformFindAction")
}

struct SearchableMarkdownView: NSViewRepresentable {
    let markdown: String
    let theme: ThemeDefinition
    let fontSize: CGFloat
    let fullWidth: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.postsFrameChangedNotifications = true

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.isRichText = true
        textView.drawsBackground = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 8
        textView.linkTextAttributes = [
            .cursor: NSCursor.pointingHand,
        ]

        scrollView.documentView = textView

        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView

        context.coordinator.findObserver = NotificationCenter.default.addObserver(
            forName: .mdownPerformFindAction,
            object: nil,
            queue: .main
        ) { notification in
            guard let textView = context.coordinator.textView else { return }
            textView.window?.makeFirstResponder(textView)
            let tag = notification.userInfo?["tag"] as? Int ?? 1
            let menuItem = NSMenuItem()
            menuItem.tag = tag
            textView.performFindPanelAction(menuItem)
        }

        context.coordinator.frameObserver = NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: scrollView,
            queue: .main
        ) { _ in
            context.coordinator.updateInsets()
        }

        updateContent(textView: textView, scrollView: scrollView, coordinator: context.coordinator)

        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        context.coordinator.fullWidth = fullWidth
        updateContent(textView: textView, scrollView: scrollView, coordinator: context.coordinator)
    }

    private func updateContent(textView: NSTextView, scrollView: NSScrollView, coordinator: Coordinator) {
        let contentHash = markdown.hashValue
        let needsUpdate = contentHash != coordinator.lastContentHash
            || theme.id != coordinator.lastThemeID
            || fontSize != coordinator.lastFontSize

        if needsUpdate {
            let attrStr = MarkdownStyledString.build(
                from: markdown, theme: theme, fontSize: fontSize
            )
            textView.textStorage?.setAttributedString(attrStr)
            coordinator.lastContentHash = contentHash
            coordinator.lastThemeID = theme.id
            coordinator.lastFontSize = fontSize
        }

        let bgColor = NSColor(theme.background)
        textView.backgroundColor = bgColor
        scrollView.backgroundColor = bgColor

        coordinator.fullWidth = fullWidth
        coordinator.updateInsets()
    }

    class Coordinator {
        var textView: NSTextView?
        var scrollView: NSScrollView?
        var findObserver: Any?
        var frameObserver: Any?
        var fullWidth = true
        var lastContentHash: Int = 0
        var lastThemeID = ""
        var lastFontSize: CGFloat = 0

        func updateInsets() {
            guard let textView, let scrollView else { return }
            let viewWidth = scrollView.contentSize.width
            let vertPadding: CGFloat = fullWidth ? 16 : 32

            if !fullWidth && viewWidth > 800 {
                let horizontalInset = (viewWidth - 800) / 2
                textView.textContainerInset = NSSize(width: horizontalInset, height: vertPadding)
            } else {
                textView.textContainerInset = NSSize(
                    width: fullWidth ? 16 : 40,
                    height: vertPadding
                )
            }
        }

        deinit {
            if let findObserver { NotificationCenter.default.removeObserver(findObserver) }
            if let frameObserver { NotificationCenter.default.removeObserver(frameObserver) }
        }
    }
}

// MARK: - Markdown → NSAttributedString

enum MarkdownStyledString {
    static func build(
        from markdown: String, theme: ThemeDefinition, fontSize: CGFloat
    ) -> NSAttributedString {
        MarkdownRenderer.render(markdown: markdown, theme: theme, fontSize: fontSize)
    }
}
