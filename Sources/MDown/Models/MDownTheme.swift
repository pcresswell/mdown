import MarkdownUI
import SwiftUI

enum MDownTheme {
    static func build(from definition: ThemeDefinition, fontSize: CGFloat) -> Theme {
        Theme()
            // Base text style
            .text {
                FontSize(fontSize)
                ForegroundColor(definition.text)
            }
            // Inline code
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.88))
                ForegroundColor(definition.codeColor)
                BackgroundColor(definition.codeBlockBackground.opacity(0.6))
            }
            // Bold
            .strong {
                FontWeight(.semibold)
            }
            // Italic
            .emphasis {
                FontStyle(.italic)
            }
            // Strikethrough
            .strikethrough {
                StrikethroughStyle(.single)
            }
            // Links
            .link {
                ForegroundColor(definition.linkColor)
            }
            // Heading 1
            .heading1 { configuration in
                VStack(alignment: .leading, spacing: 8) {
                    configuration.label
                        .markdownTextStyle {
                            FontSize(.em(2.0))
                            FontWeight(.bold)
                            ForegroundColor(definition.headingColor)
                        }
                    Rectangle()
                        .fill(definition.thematicBreakColor)
                        .frame(height: 1)
                }
                .markdownMargin(top: 24, bottom: 16)
            }
            // Heading 2
            .heading2 { configuration in
                VStack(alignment: .leading, spacing: 6) {
                    configuration.label
                        .markdownTextStyle {
                            FontSize(.em(1.5))
                            FontWeight(.semibold)
                            ForegroundColor(definition.headingColor)
                        }
                    Rectangle()
                        .fill(definition.thematicBreakColor)
                        .frame(height: 1)
                }
                .markdownMargin(top: 24, bottom: 16)
            }
            // Heading 3
            .heading3 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontSize(.em(1.25))
                        FontWeight(.semibold)
                        ForegroundColor(definition.headingColor)
                    }
                    .markdownMargin(top: 24, bottom: 16)
            }
            // Heading 4
            .heading4 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontSize(.em(1.1))
                        FontWeight(.semibold)
                        ForegroundColor(definition.headingColor)
                    }
                    .markdownMargin(top: 24, bottom: 16)
            }
            // Heading 5
            .heading5 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontSize(.em(1.0))
                        FontWeight(.semibold)
                        ForegroundColor(definition.headingColor)
                    }
                    .markdownMargin(top: 24, bottom: 16)
            }
            // Heading 6
            .heading6 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontSize(.em(0.85))
                        FontWeight(.semibold)
                        ForegroundColor(definition.headingColor)
                    }
                    .markdownMargin(top: 24, bottom: 16)
            }
            // Paragraph
            .paragraph { configuration in
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .relativeLineSpacing(.em(0.25))
                    .markdownMargin(top: 0, bottom: 16)
            }
            // Blockquote
            .blockquote { configuration in
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(definition.blockquoteBorder)
                        .frame(width: 4)
                    configuration.label
                        .markdownTextStyle {
                            ForegroundColor(definition.text.opacity(0.8))
                        }
                        .relativePadding(.horizontal, length: .em(1))
                }
                .padding(.vertical, 4)
                .background(definition.blockquoteBackground)
                .markdownMargin(top: 0, bottom: 16)
            }
            // Code block
            .codeBlock { configuration in
                ScrollView(.horizontal) {
                    configuration.label
                        .fixedSize(horizontal: false, vertical: true)
                        .relativeLineSpacing(.em(0.25))
                        .markdownTextStyle {
                            FontFamilyVariant(.monospaced)
                            FontSize(.em(0.85))
                            ForegroundColor(definition.text)
                        }
                        .padding(16)
                }
                .background(definition.codeBlockBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .markdownMargin(top: 0, bottom: 16)
            }
            // List items
            .listItem { configuration in
                configuration.label
                    .markdownMargin(top: .em(0.25))
            }
            // Task list markers
            .taskListMarker { configuration in
                Image(systemName: configuration.isCompleted ? "checkmark.square.fill" : "square")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(definition.linkColor)
                    .imageScale(.small)
            }
            // Table
            .table { configuration in
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .markdownTableBorderStyle(.init(color: definition.tableBorder))
                    .markdownTableBackgroundStyle(
                        .alternatingRows(
                            definition.background,
                            definition.tableStripeBackground,
                            header: definition.tableHeaderBackground
                        )
                    )
                    .markdownMargin(top: 0, bottom: 16)
            }
            .tableCell { configuration in
                configuration.label
                    .markdownTextStyle {
                        if configuration.row == 0 {
                            FontWeight(.semibold)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 13)
                    .relativeLineSpacing(.em(0.25))
            }
            // Thematic break (horizontal rule)
            .thematicBreak {
                Divider()
                    .overlay(definition.thematicBreakColor)
                    .markdownMargin(top: 24, bottom: 24)
            }
            // Image
            .image { configuration in
                configuration.label
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .markdownMargin(top: 0, bottom: 16)
            }
    }
}
