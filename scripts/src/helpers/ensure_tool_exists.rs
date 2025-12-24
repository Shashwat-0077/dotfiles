use anyhow::Result;
use which::which;

/// Ensure binary exists; return error if not.
pub fn ensure_tool_exists(bin: &str) -> Result<()> {
    match which(bin) {
        Ok(_) => Ok(()),
        Err(_) => anyhow::bail!(
            "Required tool `{}` not found in PATH. Please install it.",
            bin
        ),
    }
}
