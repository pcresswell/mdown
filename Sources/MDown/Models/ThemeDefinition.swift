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
    /// Baseline content density: a multiplier (≈0.5 tight … 1.6 spacious) that
    /// scales all vertical spacing — line height, paragraph, heading, list and
    /// blockquote margins. Per-theme, and overridable by the user via the
    /// density slider in the theme window (see `AppState.density`).
    var defaultDensity: CGFloat = 1.0

    // Preview swatch colors (shown in theme picker cards)
    var swatchColors: [Color] {
        [background, text, headingColor, linkColor, codeBlockBackground]
    }
}
