#!/bin/bash

set -e  # stop on error

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <EFI_PARTITION> <DISK_PARTITION>"
    echo "Example: $0 /dev/nvme0n1p5 /dev/nvme0n1p6"
    exit 1
fi

EFI="$1"
DISK="$2"

echo "🚀 Starting Btrfs setup"
echo "EFI Partition: $EFI"
echo "Disk Partition: $DISK"
sleep 2

echo "🔧 Formatting Partitions..."
mkfs.fat -F32 "$EFI"
mkfs.btrfs -f "$DISK"

echo "📍 Mounting Disk..."
mount "$DISK" /mnt

echo "🧱 Creating Btrfs subvolumes..."
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@swap

echo "⏏️ Unmounting..."
umount /mnt

echo "📌 Mounting subvolumes..."
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@ "$DISK" /mnt

mkdir -p /mnt/{boot,home,var/log,var/cache/pacman/pkg,swap}

mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@home "$DISK" /mnt/home
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@log "$DISK" /mnt/var/log
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@pkg "$DISK" /mnt/var/cache/pacman/pkg
mount -o noatime,ssd,space_cache=v2,discard=async,subvol=@swap "$DISK" /mnt/swap

echo "📁 Mounting EFI..."
mount "$EFI" /mnt/boot

echo "✅ Setup Complete!"
echo "Mounted structure:"
lsblk -e7 -o NAME,MOUNTPOINT
