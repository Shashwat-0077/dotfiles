use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct LsblkNode {
    pub name: String,
    #[serde(default)]
    pub size: String,
    #[serde(rename = "type")]
    pub dev_type: String,
    #[serde(default)]
    pub model: Option<String>,
}

#[derive(Debug, Clone)]
pub struct Disk {
    pub name: String,
    pub path: String,
    pub size: String,
    pub model: String,
}

#[derive(Debug, Clone)]
pub struct FreeRegion {
    pub start: String,
    pub end: String,
    pub size: String,
    pub size_bytes: u64,
}

// ---------------------------------------------------------
// Partition plan from user input
// ---------------------------------------------------------
#[derive(Debug)]
pub struct PartitionPlan {
    pub efi_size_mb: u64,
    pub linux_size_mb: u64,
}

// ---------------------------------------------------------
// Created partitions info
// ---------------------------------------------------------
#[derive(Debug)]
pub struct CreatedPartitions {
    pub efi_partition: String,
    pub linux_partition: String,
}
