use anyhow::{Context, Result, bail};
use std::process::Command;

use crate::colors;
use crate::commands::core::disk_setup::structs::CreatedPartitions;
use crate::commands::core::disk_setup::structs::Disk;
use crate::commands::core::disk_setup::structs::FreeRegion;
use crate::commands::core::disk_setup::structs::LsblkNode;
use crate::commands::core::disk_setup::structs::PartitionPlan;
use crate::helpers::run_out;
use dialoguer::{Confirm, Input};

// ---------------------------------------------------------
// List disks
// ---------------------------------------------------------
pub fn list_block_disks() -> Result<Vec<Disk>> {
    let out = run_out(Command::new("lsblk").args(["-J", "-o", "NAME,SIZE,TYPE,MODEL"]))
        .context("Failed running lsblk")?;

    let root: serde_json::Value =
        serde_json::from_str(&out).context("Failed parsing lsblk JSON")?;

    let mut disks = Vec::new();

    if let Some(devs) = root.get("blockdevices").and_then(|v| v.as_array()) {
        for d in devs {
            let node: LsblkNode =
                serde_json::from_value(d.clone()).context("Failed parsing lsblk node")?;

            if node.dev_type == "disk" {
                disks.push(Disk {
                    name: node.name.clone(),
                    path: format!("/dev/{}", node.name),
                    size: node.size.clone(),
                    model: node.model.unwrap_or_default(),
                });
            }
        }
    }

    Ok(disks)
}

// ---------------------------------------------------------
// Disk selector
// ---------------------------------------------------------
pub fn select_disk_simple(disks: &[Disk]) -> Result<String> {
    if disks.is_empty() {
        bail!("No disks found on system.");
    }

    println!("\n{}\n", colors::header("Available Disks"));

    // Calculate column widths dynamically
    let max_path_len = disks.iter().map(|d| d.path.len()).max().unwrap_or(10);
    let max_size_len = disks.iter().map(|d| d.size.len()).max().unwrap_or(6);
    let max_model_len = disks
        .iter()
        .map(|d| if d.model.is_empty() { 1 } else { d.model.len() })
        .max()
        .unwrap_or(5);

    // Minimum widths
    let num_width = 3;
    let path_width = max_path_len.max(6);
    let size_width = max_size_len.max(4);
    let model_width = max_model_len.max(5);

    // Table header
    println!(
        "  {:<num_w$}  {:<path_w$}  {:<size_w$}  {:<model_w$}",
        "#",
        "Device",
        "Size",
        "Model",
        num_w = num_width,
        path_w = path_width,
        size_w = size_width,
        model_w = model_width
    );
    println!();

    // Table rows
    for (i, d) in disks.iter().enumerate() {
        let model = if d.model.is_empty() { "-" } else { &d.model };
        println!(
            "  {:<num_w$}  {:<path_w$}  {:<size_w$}  {:<model_w$}",
            i + 1,
            d.path,
            d.size,
            model,
            num_w = num_width,
            path_w = path_width,
            size_w = size_width,
            model_w = model_width
        );
    }

    println!();

    // Prompt for selection
    loop {
        let input: String = Input::new()
            .with_prompt(colors::info(&format!(
                "Select disk (1-{}) or ENTER to cancel",
                disks.len()
            )))
            .allow_empty(true)
            .interact_text()
            .context("Disk selection aborted")?;

        if input.trim().is_empty() {
            bail!("Disk selection cancelled.");
        }

        match input.trim().parse::<usize>() {
            Ok(n) if n >= 1 && n <= disks.len() => {
                let chosen = &disks[n - 1].path;
                println!("{}\n", colors::success(&format!("✓ Selected: {}", chosen)));
                return Ok(chosen.clone());
            }
            _ => {
                println!("{}", colors::warn("Invalid selection. Try again."));
            }
        }
    }
}

// ---------------------------------------------------------
// Check if disk has a partition table
// ---------------------------------------------------------
pub fn check_partition_table(disk_path: &str) -> Result<bool> {
    let result = Command::new("parted")
        .args(["-s", disk_path, "print"])
        .output()
        .context("Failed to check partition table")?;

    // If exit code is 0, partition table exists
    Ok(result.status.success())
}

// ---------------------------------------------------------
// Create GPT partition table
// ---------------------------------------------------------
pub fn create_partition_table(disk_path: &str, dry_run: bool) -> Result<()> {
    println!(
        "{}",
        colors::warn(&format!("Disk {} has no partition table", disk_path))
    );

    let confirmed = Confirm::new()
        .with_prompt(colors::info(
            "Create a new GPT partition table? This will erase all data!",
        ))
        .default(false)
        .interact()
        .context("Failed to get confirmation")?;

    if !confirmed {
        bail!("User declined to create partition table");
    }

    if dry_run {
        println!(
            "{}",
            colors::info("[DRY RUN] Would create GPT partition table")
        );
        return Ok(());
    }

    println!("{}", colors::info("Creating GPT partition table..."));

    let status = Command::new("parted")
        .args(["-s", disk_path, "mklabel", "gpt"])
        .status()
        .context("Failed to create partition table")?;

    if !status.success() {
        bail!("Failed to create GPT partition table");
    }

    println!("{}", colors::success("✓ GPT partition table created"));

    Ok(())
}

// ---------------------------------------------------------
// Get disk size in bytes
// ---------------------------------------------------------
pub fn get_disk_size(disk_path: &str) -> Result<u64> {
    let out = run_out(Command::new("blockdev").args(["--getsize64", disk_path]))
        .context("Failed to get disk size")?;

    out.trim()
        .parse::<u64>()
        .context("Failed to parse disk size")
}

// ---------------------------------------------------------
// List free regions using parted
// ---------------------------------------------------------
pub fn list_free_regions(disk_path: &str) -> Result<Vec<FreeRegion>> {
    let out =
        run_out(Command::new("parted").args(["-s", "-m", disk_path, "unit", "B", "print", "free"]))
            .context("Failed running parted")?;

    let mut regions = Vec::new();

    for line in out.lines() {
        let parts: Vec<&str> = line.split(':').collect();

        // Free space lines have "free" as the 5th field
        if parts.len() >= 5 && parts[4] == "free" {
            let start = parts[0].trim_end_matches('B').to_string();
            let end = parts[1].trim_end_matches('B').to_string();
            let size = parts[2].trim_end_matches('B').to_string();

            if let Ok(size_bytes) = size.parse::<u64>() {
                // Only show regions larger than 1MB
                if size_bytes > 1_048_576 {
                    regions.push(FreeRegion {
                        start: format_bytes(start.parse().unwrap_or(0)),
                        end: format_bytes(end.parse().unwrap_or(0)),
                        size: format_bytes(size_bytes),
                        size_bytes,
                    });
                }
            }
        }
    }

    Ok(regions)
}

// ---------------------------------------------------------
// Display free regions or disk size
// ---------------------------------------------------------
pub fn display_free_regions(regions: &[FreeRegion], disk_path: &str) -> Result<()> {
    if regions.is_empty() {
        println!("{}", colors::warn("No free space regions found."));

        // Show total disk size instead
        match get_disk_size(disk_path) {
            Ok(size_bytes) => {
                println!(
                    "{}",
                    colors::info(&format!("Total disk size: {}", format_bytes(size_bytes)))
                );
                println!(
                    "{}",
                    colors::info(&format!(
                        "Usable space: ~{}",
                        format_bytes(size_bytes - 34_603_008)
                    )) // GPT overhead ~33MB
                );
            }
            Err(_) => {
                println!("{}", colors::warn("Could not determine disk size"));
            }
        }

        println!();
        return Ok(());
    }

    println!("\n{}\n", colors::header("Free Space Regions"));

    let max_start_len = regions.iter().map(|r| r.start.len()).max().unwrap_or(10);
    let max_end_len = regions.iter().map(|r| r.end.len()).max().unwrap_or(10);
    let max_size_len = regions.iter().map(|r| r.size.len()).max().unwrap_or(10);

    let start_width = max_start_len.max(5);
    let end_width = max_end_len.max(3);
    let size_width = max_size_len.max(4);

    println!(
        "  {:<start_w$}  {:<end_w$}  {:<size_w$}",
        "Start",
        "End",
        "Size",
        start_w = start_width,
        end_w = end_width,
        size_w = size_width
    );
    println!();

    for r in regions {
        println!(
            "  {:<start_w$}  {:<end_w$}  {:<size_w$}",
            r.start,
            r.end,
            r.size,
            start_w = start_width,
            end_w = end_width,
            size_w = size_width
        );
    }
    println!();

    Ok(())
}

// ---------------------------------------------------------
// Get partition plan from user (with disk size fallback)
// ---------------------------------------------------------
pub fn get_partition_plan(free_regions: &[FreeRegion], disk_path: &str) -> Result<PartitionPlan> {
    let total_free_bytes = if free_regions.is_empty() {
        // No free regions found, use total disk size minus GPT overhead
        let disk_size = get_disk_size(disk_path)?;
        let gpt_overhead = 34_603_008; // ~33MB for GPT tables

        if disk_size <= gpt_overhead {
            bail!("Disk is too small for partitioning");
        }

        disk_size - gpt_overhead
    } else {
        free_regions.iter().map(|r| r.size_bytes).sum()
    };

    let total_free_mb = total_free_bytes / 1_048_576;

    println!(
        "{}",
        colors::info(&format!(
            "Available space: {} MB ({:.2} GB)",
            total_free_mb,
            total_free_mb as f64 / 1024.0
        ))
    );
    println!();

    // Get EFI partition size
    let efi_size: String = Input::new()
        .with_prompt(colors::info("EFI partition size in MB (recommended: 1024)"))
        .default("1024".to_string())
        .interact_text()
        .context("Failed to get EFI size")?;

    let efi_size_mb: u64 = efi_size
        .trim()
        .parse()
        .context("Invalid EFI size - must be a number")?;

    if efi_size_mb < 512 {
        bail!("EFI partition must be at least 512 MB");
    }

    if efi_size_mb > total_free_mb {
        bail!("EFI partition size exceeds available space");
    }

    // Get Linux partition size
    let remaining_mb = total_free_mb - efi_size_mb;

    println!(
        "{}",
        colors::info(&format!(
            "Remaining space: {} MB ({:.2} GB)",
            remaining_mb,
            remaining_mb as f64 / 1024.0
        ))
    );

    let linux_size: String = Input::new()
        .with_prompt(colors::info(&format!(
            "Linux partition size in MB (max: {})",
            remaining_mb
        )))
        .default(remaining_mb.to_string())
        .interact_text()
        .context("Failed to get Linux partition size")?;

    let linux_size_mb: u64 = linux_size
        .trim()
        .parse()
        .context("Invalid Linux size - must be a number")?;

    if linux_size_mb > remaining_mb {
        bail!("Linux partition size exceeds remaining space");
    }

    println!();
    println!("{}", colors::success("Partition Plan:"));
    println!(
        "  EFI:   {} MB ({:.2} GB)",
        efi_size_mb,
        efi_size_mb as f64 / 1024.0
    );
    println!(
        "  Linux: {} MB ({:.2} GB)",
        linux_size_mb,
        linux_size_mb as f64 / 1024.0
    );
    println!();

    Ok(PartitionPlan {
        efi_size_mb,
        linux_size_mb,
    })
}

// ---------------------------------------------------------
// Create partitions using parted
// ---------------------------------------------------------
pub fn create_partitions(
    disk_path: &str,
    plan: &PartitionPlan,
    dry_run: bool,
) -> Result<CreatedPartitions> {
    use crate::helpers::run_show;
    use std::process::Command;

    println!("\n{}", colors::header("Creating Partitions (using sgdisk)"));

    // Calculate partition boundaries (for display only)
    let efi_start = 1; // 1 MiB (informational)
    let efi_end = efi_start + plan.efi_size_mb;
    let linux_start = efi_end;
    let linux_end = linux_start + plan.linux_size_mb;

    if dry_run {
        println!("{}", colors::info("[DRY RUN] Would create:"));
        println!(
            "  EFI partition: {}MiB - {}MiB (size: {}MiB)",
            efi_start, efi_end, plan.efi_size_mb
        );
        println!(
            "  Linux partition: {}MiB - {}MiB (size: {}MiB)",
            linux_start, linux_end, plan.linux_size_mb
        );

        // Return fake partition names for dry run (respect nvme naming)
        let (efi_fake, linux_fake) = if disk_path.contains("nvme") || disk_path.contains("mmcblk") {
            (format!("{}p1", disk_path), format!("{}p2", disk_path))
        } else {
            (format!("{}1", disk_path), format!("{}2", disk_path))
        };

        return Ok(CreatedPartitions {
            efi_partition: efi_fake,
            linux_partition: linux_fake,
        });
    }

    // Ensure sgdisk exists? (optional) - you may prefer calling ensure_tool_exists earlier
    // Create EFI partition: number 1, size +{efi_size_mb}M, type ef00 (EFI System)
    println!("{}", colors::info("Creating EFI partition (sgdisk)..."));
    // sgdisk -n 1:0:+{size}M -t 1:ef00 <disk>
    let mut cmd = Command::new("sgdisk");
    cmd.args([
        "-n",
        &format!("1:0:+{}M", plan.efi_size_mb),
        "-t",
        "1:ef00",
        disk_path,
    ]);

    // run_show prints the command and respects dry_run (we are not in dry_run here, but keep consistency)
    run_show(&mut cmd, dry_run).context("Failed to run sgdisk to create EFI partition")?;

    // Create Linux partition: number 2, use remaining space (0 means rest), type 8300
    println!("{}", colors::info("Creating Linux partition (sgdisk)..."));
    // sgdisk -n 2:0:0 -t 2:8300 <disk>
    let mut cmd2 = Command::new("sgdisk");
    cmd2.args(["-n", "2:0:0", "-t", "2:8300", disk_path]);

    run_show(&mut cmd2, dry_run).context("Failed to run sgdisk to create Linux partition")?;

    println!("{}", colors::success("✓ Partitions created with sgdisk"));

    // Determine partition naming scheme (sda1/sda2 vs nvme0n1p1/nvme0n1p2)
    let (efi_part, linux_part) = if disk_path.contains("nvme") || disk_path.contains("mmcblk") {
        (format!("{}p1", disk_path), format!("{}p2", disk_path))
    } else {
        (format!("{}1", disk_path), format!("{}2", disk_path))
    };

    // Give kernel a moment to see new partition table (and tell it explicitly)
    std::thread::sleep(std::time::Duration::from_millis(500));
    let _ = Command::new("partprobe").arg(disk_path).status();
    // optionally run `udevadm settle` if you want to be extra sure:
    let _ = Command::new("udevadm").args(["settle"]).status();

    println!();
    println!("{}", colors::info(&format!("EFI partition: {}", efi_part)));
    println!(
        "{}",
        colors::info(&format!("Linux partition: {}", linux_part))
    );

    Ok(CreatedPartitions {
        efi_partition: efi_part,
        linux_partition: linux_part,
    })
}

// ---------------------------------------------------------
// Format partitions
// ---------------------------------------------------------
pub fn format_partitions(partitions: &CreatedPartitions, dry_run: bool) -> Result<()> {
    println!("{}", colors::header("Formatting Partitions"));

    if dry_run {
        println!("{}", colors::info("[DRY RUN] Would format:"));
        println!("  {} as FAT32 (EFI)", partitions.efi_partition);
        println!("  {} as Btrfs (Linux)", partitions.linux_partition);
        return Ok(());
    }

    // Format EFI partition as FAT32
    println!(
        "{}",
        colors::info(&format!(
            "Formatting {} as FAT32...",
            partitions.efi_partition
        ))
    );

    let status = Command::new("mkfs.fat")
        .args(["-F", "32", "-n", "EFI", &partitions.efi_partition])
        .status()
        .context("Failed to format EFI partition")?;

    if !status.success() {
        bail!("Failed to format EFI partition as FAT32");
    }

    println!("{}", colors::success("✓ EFI partition formatted as FAT32"));

    // Format Linux partition as Btrfs
    println!(
        "{}",
        colors::info(&format!(
            "Formatting {} as Btrfs...",
            partitions.linux_partition
        ))
    );

    let status = Command::new("mkfs.btrfs")
        .args(["-f", "-L", "ROOT", &partitions.linux_partition])
        .status()
        .context("Failed to format Linux partition")?;

    if !status.success() {
        bail!("Failed to format Linux partition as Btrfs");
    }

    println!(
        "{}",
        colors::success("✓ Linux partition233 formatted as Btrfs")
    );
    println!();

    Ok(())
}

// ---------------------------------------------------------
// Format bytes to human readable
// ---------------------------------------------------------
fn format_bytes(bytes: u64) -> String {
    const KB: u64 = 1024;
    const MB: u64 = KB * 1024;
    const GB: u64 = MB * 1024;
    const TB: u64 = GB * 1024;

    if bytes >= TB {
        format!("{:.2} TB", bytes as f64 / TB as f64)
    } else if bytes >= GB {
        format!("{:.2} GB", bytes as f64 / GB as f64)
    } else if bytes >= MB {
        format!("{:.2} MB", bytes as f64 / MB as f64)
    } else if bytes >= KB {
        format!("{:.2} KB", bytes as f64 / KB as f64)
    } else {
        format!("{} B", bytes)
    }
}
