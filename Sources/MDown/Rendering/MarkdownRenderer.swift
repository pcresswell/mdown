import AppKit
import SwiftUI
import cmark_gfm
import cmark_gfm_extensions

enum MarkdownRenderer {

    static func render(
        markdown: String, theme: ThemeDefinition, fontSize: CGFloat
    ) -> NSAttributedString {
        let html = markdownToHTML(markdown)
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
                string: markdown,
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

        cmark_parser_feed(parser, markdown, markdown.utf8.count)

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

    private static func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
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
