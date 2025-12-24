pub mod helpers;
pub mod structs;

use anyhow::Ok;

use crate::colors;

#[derive(clap::Args, Debug)]
/// Peek inside a basket (tree object) by its ID
pub struct DiskSetupArgs {
    /// If set, do not perform any changes, just simulate
    #[clap(long)]
    pub dry_run: bool,
}

pub fn handle(args: DiskSetupArgs) -> anyhow::Result<()> {
    // Select disk
    let disks = helpers::list_block_disks()?;
    let chosen = helpers::select_disk_simple(&disks)?;

    // Check if disk has a partition table
    let has_pt = helpers::check_partition_table(&chosen)?;

    if !has_pt {
        // Create partition table if needed
        helpers::create_partition_table(&chosen, args.dry_run)?;
    }

    // Show free regions (or total disk size if no free regions)
    let free_regions = helpers::list_free_regions(&chosen)?;
    helpers::display_free_regions(&free_regions, &chosen)?;

    // Get partition plan from user (handles both cases)
    let plan = helpers::get_partition_plan(&free_regions, &chosen)?;

    // Create partitions
    let partitions = helpers::create_partitions(&chosen, &plan, args.dry_run)?;

    // Format partitions
    helpers::format_partitions(&partitions, args.dry_run)?;

    println!("{}", colors::success("Disk setup completed successfully!"));
    println!();
    println!("{}", colors::info("Partition Details:"));
    println!("  EFI:   {} (FAT32)", partitions.efi_partition);
    println!("  Linux: {} (Btrfs)", partitions.linux_partition);

    Ok(())
}
