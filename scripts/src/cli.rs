use crate::commands::Commands;
use clap::Parser;

#[derive(Parser, Debug)]
#[command(
    name = "sharch",
    version,
    author = "Shashwat Gupta",
    about = "A clean, reliable Arch Linux installer written in Rust.",
    long_about = "sharch is a minimal, safe, and scriptable Arch Linux installer built in Rust.\n\
It guides you through each installation step — networking, disk setup, filesystem creation, base system bootstrap, and post-install configuration — with clear prompts and strict safety checks.\n\n\
Designed for both interactive users and automated workflows, sharch keeps installation logic predictable, reproducible, and easy to extend."
)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}
