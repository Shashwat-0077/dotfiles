use std::process::Command;

use crate::helpers::run_show;

/// Install packages using pacman (inside live ISO or chroot).
pub fn pacman_install(pkgs: &[&str], dry_run: bool) -> anyhow::Result<()> {
    if pkgs.is_empty() {
        return Ok(()); // nothing to install
    }

    let mut cmd = Command::new("pacman");
    cmd.args([
        "-Sy",
        "--noconfirm",
        "--needed", // don't reinstall existing packages
    ]);
    cmd.args(pkgs);

    run_show(&mut cmd, dry_run)?;
    Ok(())
}
