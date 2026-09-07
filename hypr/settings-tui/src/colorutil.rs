//! Hyprland color literal <-> RGB helpers, for rendering swatches.

/// Parse rgba(RRGGBBAA) / rgb(RRGGBB) into (r, g, b, a).
pub fn parse_hypr_color(text: &str) -> Option<(u8, u8, u8, u8)> {
    let t = text.trim();
    let inner = t
        .strip_prefix("rgba(")
        .or_else(|| t.strip_prefix("rgb("))
        .and_then(|s| s.strip_suffix(')'))?;
    let hex = inner.trim();
    match hex.len() {
        8 => Some((
            u8::from_str_radix(&hex[0..2], 16).ok()?,
            u8::from_str_radix(&hex[2..4], 16).ok()?,
            u8::from_str_radix(&hex[4..6], 16).ok()?,
            u8::from_str_radix(&hex[6..8], 16).ok()?,
        )),
        6 => Some((
            u8::from_str_radix(&hex[0..2], 16).ok()?,
            u8::from_str_radix(&hex[2..4], 16).ok()?,
            u8::from_str_radix(&hex[4..6], 16).ok()?,
            255,
        )),
        _ => None,
    }
}

/// RGB as it would roughly look composited over a black background —
/// close enough for a terminal swatch preview.
pub fn blended_rgb(text: &str) -> Option<(u8, u8, u8)> {
    let (r, g, b, a) = parse_hypr_color(text)?;
    let af = a as f32 / 255.0;
    Some(((r as f32 * af) as u8, (g as f32 * af) as u8, (b as f32 * af) as u8))
}
