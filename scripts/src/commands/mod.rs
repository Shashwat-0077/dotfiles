use clap::Subcommand;

pub mod core;

#[derive(Subcommand, Debug)]
pub enum Commands {
    /// Says hello
    DiskSetup(core::disk_setup::DiskSetupArgs),
}
