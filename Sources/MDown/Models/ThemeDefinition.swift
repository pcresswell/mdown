import SwiftUI

struct ThemeDefinition: Identifiable, Equatable {
    let id: String
    let name: String

    // Background
    let background: Color

    // Text colors
    let text: Color
    let headingColor: Color
    let linkColor: Color
    let codeColor: Color

    // Block colors
    let codeBlockBackground: Color
    let blockquoteBorder: Color
    let blockquoteBackground: Color
    let tableBorder: Color
    let tableHeaderBackground: Color
    let tableStripeBackground: Color
    let thematicBreakColor: Color

    // Layout
    /// Vertical space above section headings (h2–h6), in `em` units. Larger
    /// values give more breathing room between sections. Per-theme so themes
    /// can tune their own density; defaults to a roomy value.
    var headingTopMargin: CGFloat = 2.4

    // Preview swatch colors (shown in theme picker cards)
    var swatchColors: [Color] {
        [background, text, headingColor, linkColor, codeBlockBackground]
    }
}
