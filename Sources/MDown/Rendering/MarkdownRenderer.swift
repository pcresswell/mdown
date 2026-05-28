import AppKit
import SwiftUI
import cmark_gfm
import cmark_gfm_extensions

enum MarkdownRenderer {

    /// Async entry point — renders any mermaid fenced code blocks to images
    /// before building the final attributed string.
    @MainActor
    static func render(
        markdown: String, theme: ThemeDefinition, fontSize: CGFloat
    ) async -> NSAttributedString {
        var html = markdownToHTML(markdown)
        html = await replaceMermaidBlocks(in: html, theme: theme)
        return buildAttributedString(html: html, theme: theme, fontSize: fontSize)
    }

    /// Synchronous entry point — skips mermaid rendering (diagrams remain as
    /// code blocks). Kept for callers that can't await.
    static func render(
        markdown: String, theme: ThemeDefinition, fontSize: CGFloat
    ) -> NSAttributedString {
        let html = markdownToHTML(markdown)
        return buildAttributedString(html: html, theme: theme, fontSize: fontSize)
    }

    private static func buildAttributedString(
        html: String, theme: ThemeDefinition, fontSize: CGFloat
    ) -> NSAttributedString {
        let styledHTML = wrapWithCSS(html: html, theme: theme, fontSize: fontSize)

        guard let data = styledHTML.data(using: .utf8),
            let attrStr = NSAttributedString(
                html: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue,
                ],
                documentAttributes: nil)
        else {
            return NSAttributedString(
                string: html,
                attributes: [
                    .font: NSFont.systemFont(ofSize: fontSize),
                    .foregroundColor: NSColor(theme.text),
                ])
        }

        // NSAttributedString(html:) sets its own background on the text.
        // Strip it so the NSTextView background shows through.
        let mutable = NSMutableAttributedString(attributedString: attrStr)
        let fullRange = NSRange(location: 0, length: mutable.length)
        mutable.removeAttribute(.backgroundColor, range: fullRange)

        return mutable
    }

    // MARK: - cmark-gfm parsing

    private static func markdownToHTML(_ markdown: String) -> String {
        cmark_gfm_core_extensions_ensure_registered()

        guard let parser = cmark_parser_new(CMARK_OPT_DEFAULT) else {
            return escapeHTML(markdown)
        }
        defer { cmark_parser_free(parser) }

        let extensions = ["autolink", "strikethrough", "tagfilter", "tasklist", "table"]
        for name in extensions {
            if let ext = cmark_find_syntax_extension(name) {
                cmark_parser_attach_syntax_extension(parser, ext)
            }
        }

        let preprocessed = ensureBlockSeparation(markdown)
        cmark_parser_feed(parser, preprocessed, preprocessed.utf8.count)

        guard let document = cmark_parser_finish(parser) else {
            return escapeHTML(markdown)
        }
        defer { cmark_node_free(document) }

        guard let cString = cmark_render_html(
            document, CMARK_OPT_DEFAULT | CMARK_OPT_UNSAFE, cmark_parser_get_syntax_extensions(parser))
        else {
            return escapeHTML(markdown)
        }

        let html = String(cString: cString)
        free(cString)
        return html
    }

    /// Insert blank lines between consecutive non-empty lines that each start
    /// with a numbered bold pattern (e.g. "**1. …**"), so cmark treats them as
    /// separate paragraphs instead of merging them into one.
    private static func ensureBlockSeparation(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: "\n")
        guard lines.count > 1 else { return markdown }

        // Matches lines starting with optional whitespace then **<digit(s)>.
        let numberedBoldPattern = #"^\s*\*\*\d+\."#
        let regex = try! NSRegularExpression(pattern: numberedBoldPattern)

        func isNumberedBold(_ line: String) -> Bool {
            let range = NSRange(line.startIndex..., in: line)
            return regex.firstMatch(in: line, range: range) != nil
        }

        var result = [lines[0]]
        for i in 1..<lines.count {
            let prev = lines[i - 1]
            let curr = lines[i]
            // Insert a blank line before a numbered-bold line when the
            // previous line is non-empty and not already blank.
            if isNumberedBold(curr) && !prev.trimmingCharacters(in: .whitespaces).isEmpty {
                result.append("")
            }
            result.append(curr)
        }
        return result.joined(separator: "\n")
    }

    private static func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func unescapeHTMLEntities(_ text: String) -> String {
        // Order matters: decode &amp; last so we don't double-decode.
        text.replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
    }

    // MARK: - Mermaid

    @MainActor
    private static func replaceMermaidBlocks(in html: String, theme: ThemeDefinition) async -> String {
        let pattern = #"(?s)<pre><code class="language-mermaid">(.*?)</code></pre>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return html }
        let ns = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return html }

        let isDark = isDarkBackground(theme.background)

        // Collect (range, renderedReplacement) pairs. Render sequentially — the
        // MermaidRenderer serializes anyway and diagrams per document are few.
        struct Replacement { let range: NSRange; let replacement: String }
        var replacements: [Replacement] = []

        for match in matches {
            let range = match.range(at: 0)
            let sourceRange = match.range(at: 1)
            let rawSource = ns.substring(with: sourceRange)
            let source = unescapeHTMLEntities(rawSource).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !source.isEmpty else { continue }

            if let rendered = await MermaidRenderer.shared.render(source: source, isDark: isDark) {
                let escapedURL = rendered.url.absoluteString
                    .replacingOccurrences(of: "&", with: "&amp;")
                    .replacingOccurrences(of: "\"", with: "&quot;")
                let w = Int(rendered.logicalSize.width)
                let h = Int(rendered.logicalSize.height)
                replacements.append(Replacement(
                    range: range,
                    replacement: #"<p><img src="\#(escapedURL)" width="\#(w)" height="\#(h)" class="mermaid-diagram"></p>"#
                ))
            }
            // If rendering fails, leave the original code block in place so the
            // user still sees the source rather than nothing.
        }

        guard !replacements.isEmpty else { return html }

        let mutable = NSMutableString(string: html)
        for item in replacements.reversed() {
            mutable.replaceCharacters(in: item.range, with: item.replacement)
        }
        let finalHTML = mutable as String
        if ProcessInfo.processInfo.environment["MDOWN_DUMP_HTML"] != nil {
            let path = (NSTemporaryDirectory() as NSString).appendingPathComponent("mdown-final.html")
            try? finalHTML.write(toFile: path, atomically: true, encoding: .utf8)
        }
        return finalHTML
    }

    private static func isDarkBackground(_ color: Color) -> Bool {
        let ns = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ns.getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luminance < 0.5
    }

    // MARK: - CSS theming

    private static func wrapWithCSS(
        html: String, theme: ThemeDefinition, fontSize: CGFloat
    ) -> String {
        let text = cssColor(theme.text)
        let bg = cssColor(theme.background)
        let heading = cssColor(theme.headingColor)
        let link = cssColor(theme.linkColor)
        let code = cssColor(theme.codeColor)
        let codeBg = cssColor(theme.codeBlockBackground)
        let bqBorder = cssColor(theme.blockquoteBorder)
        let bqBg = cssColor(theme.blockquoteBackground)
        let tBorder = cssColor(theme.tableBorder)
        let tHeaderBg = cssColor(theme.tableHeaderBackground)
        let tStripeBg = cssColor(theme.tableStripeBackground)
        let hrColor = cssColor(theme.thematicBreakColor)

        return """
            <!DOCTYPE html>
            <html>
            <head>
            <meta charset="utf-8">
            <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                font-size: \(fontSize)px;
                color: \(text);
                background-color: \(bg);
                line-height: 1.6;
                word-wrap: break-word;
            }
            h1, h2, h3, h4, h5, h6 {
                color: \(heading);
                margin-top: 1.5em;
                margin-bottom: 0.75em;
                line-height: 1.3;
            }
            h1 { font-size: \(fontSize * 2.0)px; margin-top: 0.5em; }
            h2 { font-size: \(fontSize * 1.6)px; }
            h3 { font-size: \(fontSize * 1.3)px; }
            h4 { font-size: \(fontSize * 1.15)px; }
            h5 { font-size: \(fontSize * 1.05)px; }
            h6 { font-size: \(fontSize * 0.95)px; }
            a { color: \(link); }
            code {
                font-family: Menlo, Monaco, monospace;
                font-size: \(fontSize * 0.85)px;
                color: \(code);
                background-color: \(codeBg);
                padding: 2px 5px;
                border-radius: 3px;
            }
            pre {
                background-color: \(codeBg);
                padding: 12px 16px;
                border-radius: 6px;
                overflow-x: auto;
                line-height: 1.45;
                margin: 1em 0;
            }
            pre code {
                padding: 0;
                background-color: transparent;
                font-size: \(fontSize * 0.85)px;
            }
            blockquote {
                border-left: 4px solid \(bqBorder);
                background-color: \(bqBg);
                margin: 1em 0;
                padding: 0.75em 1em;
                color: \(text);
                opacity: 0.85;
            }
            blockquote p { margin: 0.4em 0; }
            hr {
                border: none;
                border-top: 2px solid \(hrColor);
                margin: 1.5em 0;
            }
            table {
                border-collapse: collapse;
                width: auto;
                margin: 1em 0;
            }
            th, td {
                border: 1px solid \(tBorder);
                padding: 6px 12px;
                text-align: left;
            }
            th {
                background-color: \(tHeaderBg);
                font-weight: 600;
            }
            tr:nth-child(even) td {
                background-color: \(tStripeBg);
            }
            ul, ol { padding-left: 2em; margin: 0.75em 0; }
            li { margin: 0.4em 0; }
            ul.contains-task-list {
                list-style-type: none;
                padding-left: 1em;
            }
            li.task-list-item { margin: 0.4em 0; }
            p { margin: 0.8em 0; }
            img { max-width: 100%; }
            img.mermaid-diagram { display: block; margin: 1em auto; max-width: 100%; height: auto; }
            </style>
            </head>
            <body>
            \(html)
            </body>
            </html>
            """
    }

    private static func cssColor(_ color: Color) -> String {
        let nsColor = NSColor(color).usingColorSpace(.sRGB)
            ?? NSColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        if a < 1.0 {
            return "rgba(\(Int(r * 255)), \(Int(g * 255)), \(Int(b * 255)), \(String(format: "%.2f", a)))"
        }
        return "rgb(\(Int(r * 255)), \(Int(g * 255)), \(Int(b * 255)))"
    }
}
