import SwiftUI

enum ThemeDefinitions {
    static let all: [ThemeDefinition] = [
        defaultLight,
        defaultDark,
        sepia,
        nord,
        solarizedLight,
        solarizedDark,
        dracula,
        monokai,
        github,
        ocean,
    ]

    // MARK: - 1. Default Light

    static let defaultLight = ThemeDefinition(
        id: "default-light",
        name: "Default Light",
        background: Color(red: 1, green: 1, blue: 1),
        text: Color(red: 0.13, green: 0.13, blue: 0.13),
        headingColor: Color(red: 0.1, green: 0.1, blue: 0.1),
        linkColor: Color(red: 0.0, green: 0.48, blue: 1.0),
        codeColor: Color(red: 0.78, green: 0.14, blue: 0.28),
        codeBlockBackground: Color(red: 0.96, green: 0.96, blue: 0.96),
        blockquoteBorder: Color(red: 0.82, green: 0.82, blue: 0.82),
        blockquoteBackground: Color(red: 0.96, green: 0.96, blue: 0.96),
        tableBorder: Color(red: 0.85, green: 0.85, blue: 0.85),
        tableHeaderBackground: Color(red: 0.95, green: 0.95, blue: 0.95),
        tableStripeBackground: Color(red: 0.98, green: 0.98, blue: 0.98),
        thematicBreakColor: Color(red: 0.85, green: 0.85, blue: 0.85)
    )

    // MARK: - 2. Default Dark

    static let defaultDark = ThemeDefinition(
        id: "default-dark",
        name: "Default Dark",
        background: Color(red: 0.11, green: 0.11, blue: 0.12),
        text: Color(red: 0.88, green: 0.88, blue: 0.9),
        headingColor: Color(red: 0.95, green: 0.95, blue: 0.97),
        linkColor: Color(red: 0.35, green: 0.68, blue: 1.0),
        codeColor: Color(red: 0.95, green: 0.55, blue: 0.66),
        codeBlockBackground: Color(red: 0.16, green: 0.16, blue: 0.18),
        blockquoteBorder: Color(red: 0.35, green: 0.35, blue: 0.38),
        blockquoteBackground: Color(red: 0.16, green: 0.16, blue: 0.18),
        tableBorder: Color(red: 0.3, green: 0.3, blue: 0.33),
        tableHeaderBackground: Color(red: 0.18, green: 0.18, blue: 0.2),
        tableStripeBackground: Color(red: 0.14, green: 0.14, blue: 0.16),
        thematicBreakColor: Color(red: 0.3, green: 0.3, blue: 0.33)
    )

    // MARK: - 3. Sepia

    static let sepia = ThemeDefinition(
        id: "sepia",
        name: "Sepia",
        background: Color(red: 0.97, green: 0.94, blue: 0.88),
        text: Color(red: 0.33, green: 0.27, blue: 0.2),
        headingColor: Color(red: 0.27, green: 0.2, blue: 0.13),
        linkColor: Color(red: 0.55, green: 0.27, blue: 0.07),
        codeColor: Color(red: 0.6, green: 0.2, blue: 0.2),
        codeBlockBackground: Color(red: 0.93, green: 0.89, blue: 0.82),
        blockquoteBorder: Color(red: 0.75, green: 0.68, blue: 0.55),
        blockquoteBackground: Color(red: 0.93, green: 0.89, blue: 0.82),
        tableBorder: Color(red: 0.8, green: 0.74, blue: 0.63),
        tableHeaderBackground: Color(red: 0.93, green: 0.89, blue: 0.82),
        tableStripeBackground: Color(red: 0.95, green: 0.92, blue: 0.85),
        thematicBreakColor: Color(red: 0.8, green: 0.74, blue: 0.63)
    )

    // MARK: - 4. Nord

    static let nord = ThemeDefinition(
        id: "nord",
        name: "Nord",
        background: Color(red: 0.18, green: 0.2, blue: 0.25),
        text: Color(red: 0.85, green: 0.87, blue: 0.91),
        headingColor: Color(red: 0.53, green: 0.75, blue: 0.82),
        linkColor: Color(red: 0.53, green: 0.75, blue: 0.82),
        codeColor: Color(red: 0.64, green: 0.75, blue: 0.55),
        codeBlockBackground: Color(red: 0.23, green: 0.26, blue: 0.32),
        blockquoteBorder: Color(red: 0.37, green: 0.51, blue: 0.67),
        blockquoteBackground: Color(red: 0.23, green: 0.26, blue: 0.32),
        tableBorder: Color(red: 0.3, green: 0.34, blue: 0.42),
        tableHeaderBackground: Color(red: 0.23, green: 0.26, blue: 0.32),
        tableStripeBackground: Color(red: 0.2, green: 0.23, blue: 0.28),
        thematicBreakColor: Color(red: 0.3, green: 0.34, blue: 0.42)
    )

    // MARK: - 5. Solarized Light

    static let solarizedLight = ThemeDefinition(
        id: "solarized-light",
        name: "Solarized Light",
        background: Color(red: 0.99, green: 0.96, blue: 0.89),
        text: Color(red: 0.4, green: 0.48, blue: 0.51),
        headingColor: Color(red: 0.15, green: 0.35, blue: 0.42),
        linkColor: Color(red: 0.15, green: 0.55, blue: 0.82),
        codeColor: Color(red: 0.82, green: 0.22, blue: 0.07),
        codeBlockBackground: Color(red: 0.93, green: 0.91, blue: 0.84),
        blockquoteBorder: Color(red: 0.58, green: 0.63, blue: 0.47),
        blockquoteBackground: Color(red: 0.93, green: 0.91, blue: 0.84),
        tableBorder: Color(red: 0.79, green: 0.78, blue: 0.7),
        tableHeaderBackground: Color(red: 0.93, green: 0.91, blue: 0.84),
        tableStripeBackground: Color(red: 0.96, green: 0.93, blue: 0.87),
        thematicBreakColor: Color(red: 0.79, green: 0.78, blue: 0.7)
    )

    // MARK: - 6. Solarized Dark

    static let solarizedDark = ThemeDefinition(
        id: "solarized-dark",
        name: "Solarized Dark",
        background: Color(red: 0.0, green: 0.17, blue: 0.21),
        text: Color(red: 0.51, green: 0.58, blue: 0.59),
        headingColor: Color(red: 0.58, green: 0.63, blue: 0.47),
        linkColor: Color(red: 0.15, green: 0.55, blue: 0.82),
        codeColor: Color(red: 0.82, green: 0.22, blue: 0.07),
        codeBlockBackground: Color(red: 0.03, green: 0.21, blue: 0.26),
        blockquoteBorder: Color(red: 0.42, green: 0.44, blue: 0.3),
        blockquoteBackground: Color(red: 0.03, green: 0.21, blue: 0.26),
        tableBorder: Color(red: 0.13, green: 0.3, blue: 0.35),
        tableHeaderBackground: Color(red: 0.03, green: 0.21, blue: 0.26),
        tableStripeBackground: Color(red: 0.01, green: 0.19, blue: 0.23),
        thematicBreakColor: Color(red: 0.13, green: 0.3, blue: 0.35)
    )

    // MARK: - 7. Dracula

    static let dracula = ThemeDefinition(
        id: "dracula",
        name: "Dracula",
        background: Color(red: 0.16, green: 0.16, blue: 0.21),
        text: Color(red: 0.97, green: 0.97, blue: 0.95),
        headingColor: Color(red: 0.74, green: 0.58, blue: 0.98),
        linkColor: Color(red: 0.54, green: 0.94, blue: 0.99),
        codeColor: Color(red: 1.0, green: 0.47, blue: 0.65),
        codeBlockBackground: Color(red: 0.21, green: 0.22, blue: 0.3),
        blockquoteBorder: Color(red: 0.74, green: 0.58, blue: 0.98),
        blockquoteBackground: Color(red: 0.21, green: 0.22, blue: 0.3),
        tableBorder: Color(red: 0.38, green: 0.39, blue: 0.53),
        tableHeaderBackground: Color(red: 0.21, green: 0.22, blue: 0.3),
        tableStripeBackground: Color(red: 0.19, green: 0.19, blue: 0.26),
        thematicBreakColor: Color(red: 0.38, green: 0.39, blue: 0.53)
    )

    // MARK: - 8. Monokai

    static let monokai = ThemeDefinition(
        id: "monokai",
        name: "Monokai",
        background: Color(red: 0.15, green: 0.16, blue: 0.13),
        text: Color(red: 0.97, green: 0.97, blue: 0.95),
        headingColor: Color(red: 0.4, green: 0.85, blue: 0.94),
        linkColor: Color(red: 0.4, green: 0.85, blue: 0.94),
        codeColor: Color(red: 0.9, green: 0.86, blue: 0.45),
        codeBlockBackground: Color(red: 0.2, green: 0.2, blue: 0.17),
        blockquoteBorder: Color(red: 0.98, green: 0.15, blue: 0.45),
        blockquoteBackground: Color(red: 0.2, green: 0.2, blue: 0.17),
        tableBorder: Color(red: 0.35, green: 0.36, blue: 0.32),
        tableHeaderBackground: Color(red: 0.2, green: 0.2, blue: 0.17),
        tableStripeBackground: Color(red: 0.17, green: 0.18, blue: 0.15),
        thematicBreakColor: Color(red: 0.35, green: 0.36, blue: 0.32)
    )

    // MARK: - 9. GitHub

    static let github = ThemeDefinition(
        id: "github",
        name: "GitHub",
        background: Color(red: 1, green: 1, blue: 1),
        text: Color(red: 0.14, green: 0.17, blue: 0.2),
        headingColor: Color(red: 0.14, green: 0.17, blue: 0.2),
        linkColor: Color(red: 0.04, green: 0.47, blue: 0.84),
        codeColor: Color(red: 0.14, green: 0.17, blue: 0.2),
        codeBlockBackground: Color(red: 0.95, green: 0.97, blue: 1.0),
        blockquoteBorder: Color(red: 0.82, green: 0.84, blue: 0.86),
        blockquoteBackground: .clear,
        tableBorder: Color(red: 0.82, green: 0.84, blue: 0.86),
        tableHeaderBackground: Color(red: 0.95, green: 0.97, blue: 1.0),
        tableStripeBackground: Color(red: 0.98, green: 0.98, blue: 0.98),
        thematicBreakColor: Color(red: 0.82, green: 0.84, blue: 0.86)
    )

    // MARK: - 10. Ocean

    static let ocean = ThemeDefinition(
        id: "ocean",
        name: "Ocean",
        background: Color(red: 0.07, green: 0.12, blue: 0.19),
        text: Color(red: 0.8, green: 0.87, blue: 0.92),
        headingColor: Color(red: 0.4, green: 0.8, blue: 0.78),
        linkColor: Color(red: 0.36, green: 0.72, blue: 0.91),
        codeColor: Color(red: 0.95, green: 0.7, blue: 0.45),
        codeBlockBackground: Color(red: 0.1, green: 0.16, blue: 0.24),
        blockquoteBorder: Color(red: 0.4, green: 0.8, blue: 0.78),
        blockquoteBackground: Color(red: 0.1, green: 0.16, blue: 0.24),
        tableBorder: Color(red: 0.2, green: 0.3, blue: 0.4),
        tableHeaderBackground: Color(red: 0.1, green: 0.16, blue: 0.24),
        tableStripeBackground: Color(red: 0.08, green: 0.14, blue: 0.21),
        thematicBreakColor: Color(red: 0.2, green: 0.3, blue: 0.4)
    )
}
