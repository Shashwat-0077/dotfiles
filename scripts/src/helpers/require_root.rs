pub fn require_root() -> anyhow::Result<()> {
    if unsafe { libc::geteuid() } == 0 {
        Ok(())
    } else {
        anyhow::bail!("This operation requires root. Please run with sudo or as root.");
    }
}
