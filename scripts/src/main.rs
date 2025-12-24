mod cli;
mod colors;
mod commands;
mod helpers;

use clap::Parser;
use commands::Commands;

fn main() {
    if let Err(err) = run() {
        eprintln!("{}", err);

        // Show the whole chain of causes (optional)
        for cause in err.chain().skip(1) {
            eprintln!("Caused by: {}", cause);
        }

        std::process::exit(1);
    }
}

fn run() -> anyhow::Result<()> {
    let cli = cli::Cli::parse();

    match cli.command {
        Commands::DiskSetup(args) => commands::core::disk_setup::handle(args),
    }
}
