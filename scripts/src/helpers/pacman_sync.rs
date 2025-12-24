use std::process::Command;

use crate::helpers::run_show;

/// Run pacman -Sy to sync package databases.
pub fn pacman_sync(dry_run: bool) -> anyhow::Result<()> {
    let mut cmd = Command::new("pacman");
    cmd.args(["-Sy"]);

    run_show(&mut cmd, dry_run)?;
    Ok(())
}
