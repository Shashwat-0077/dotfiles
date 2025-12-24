// src/colors.rs
use colored::*;

/// Headers / section titles
pub fn header(msg: &str) -> String {
    msg.bold().underline().bright_cyan().to_string()
}

/// Informational messages
pub fn info(msg: &str) -> String {
    msg.bright_blue().to_string()
}

/// Warnings
pub fn warn(msg: &str) -> String {
    msg.bright_yellow().bold().to_string()
}

/// Errors
pub fn error(msg: &str) -> String {
    msg.bright_red().bold().to_string()
}

/// Success messages
pub fn success(msg: &str) -> String {
    msg.bright_green().bold().to_string()
}

/// Highlights (numbers, paths, disk names)
pub fn highlight(msg: &str) -> String {
    msg.bold().bright_magenta().to_string()
}
