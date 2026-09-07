//! Thin wrapper around `hyprctl` for live queries and live-apply.
//!
//! Persistence to config files is handled in `config_writer` — this module
//! only ever talks to the running compositor.

use anyhow::{bail, Context, Result};
use serde_json::Value;
use std::process::Command;

fn run(args: &[&str]) -> Result<String> {
    let output = Command::new("hyprctl")
        .args(args)
        .output()
        .context("hyprctl not found — is Hyprland running?")?;
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        bail!("hyprctl {}: {}", args.join(" "), stderr.trim());
    }
    Ok(String::from_utf8_lossy(&output.stdout).into_owned())
}

pub fn query_json(args: &[&str]) -> Result<Value> {
    let mut full = vec!["-j"];
    full.extend_from_slice(args);
    let out = run(&full)?;
    serde_json::from_str(&out).with_context(|| format!("bad JSON from hyprctl {}", args.join(" ")))
}

/// Apply config changes live via `hyprctl eval <lua>`.
///
/// This Hyprland instance runs the native Lua config (hyprland.lua), which
/// disables the legacy `hyprctl keyword` path ("keyword can't work with
/// non-legacy parsers"). `eval` runs the same `hl.config(...)` /
/// `hl.animation(...)` calls the config files use, live, against the
/// running compositor.
pub fn eval_lua(code: &str) -> Result<()> {
    run(&["eval", code])?;
    Ok(())
}

pub fn monitors() -> Result<Value> {
    query_json(&["monitors", "all"])
}
