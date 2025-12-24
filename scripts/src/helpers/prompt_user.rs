use crate::colors;
use anyhow::{Context, Result};
use dialoguer::Input;

/// Prompt the user with a colored message, optional default, returns trimmed String.
pub fn prompt_user(prompt: &str, default: Option<&str>) -> Result<String> {
    let mut input = Input::<String>::new().with_prompt(colors::info(prompt));

    if let Some(def) = default {
        input = input.default(def.to_string());
    }

    let value = input.interact_text().context("User input aborted")?;

    Ok(value.trim().to_string())
}
