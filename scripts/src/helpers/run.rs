use anyhow::{Context, Result, bail};
use std::process::Command;

/// Print a command, run it, return stdout, support dry_run.
pub fn run_show(cmd: &mut Command, dry_run: bool) -> Result<String> {
    let display = format!("{:?}", cmd);
    println!("> {}", display);

    if dry_run {
        return Ok("[dry-run]".into());
    }

    let out = cmd
        .output()
        .with_context(|| format!("Failed to run: {}", display))?;

    if !out.status.success() {
        let stderr = String::from_utf8_lossy(&out.stderr);
        bail!("Command failed: {}\nstderr: {}", display, stderr);
    }

    Ok(String::from_utf8_lossy(&out.stdout).to_string())
}

/// Run a command and return its stdout as String (no printing, no dry-run).
pub fn run_out(cmd: &mut Command) -> Result<String> {
    let display = format!("{:?}", cmd);

    let out = cmd
        .output()
        .with_context(|| format!("Failed to run: {}", display))?;

    if !out.status.success() {
        let stderr = String::from_utf8_lossy(&out.stderr);
        bail!("Command failed: {}\nstderr: {}", display, stderr);
    }

    Ok(String::from_utf8_lossy(&out.stdout).to_string())
}
