# Arch Linux Installation with Btrfs Subvolumes

## Prerequisites

⚠️ **IMPORTANT**: This guide assumes you have unallocated space on your drive. Do NOT shrink/split your Windows partition from the Arch installation environment. Use Windows Disk Management to shrink the Windows partition beforehand if needed.

## Step 1: Identify Your Disk

```bash
# List all block devices
lsblk
```

Identify your target disk (e.g., `/dev/nvme0n1`). Note the existing partitions.

## Step 2: Partition the Disk

```bash
# Launch cfdisk for the target disk
cfdisk /dev/nvme0n1
```

### In cfdisk:

1. Select unallocated space
2. Create **EFI System Partition**: 1GB, Type: `EFI System`
3. Create **Linux Filesystem**: Remaining space, Type: `Linux filesystem`
4. Write changes (type `yes` to confirm)
5. Quit cfdisk

**Example partition scheme** (adjust partition numbers based on your setup):

-   `/dev/nvme0n1p5` → EFI System (1GB)
-   `/dev/nvme0n1p6` → Linux filesystem (remaining space)

## Step 3: Format Partitions

```bash
# Format EFI partition as FAT32
mkfs.fat -F32 /dev/nvme0n1p5

# Format Linux partition as Btrfs (force format if needed)
mkfs.btrfs -f /dev/nvme0n1p6
```

## Step 4: Create Btrfs Subvolumes

```bash
# Mount the Btrfs partition temporarily
mount /dev/nvme0n1p6 /mnt

# Create subvolumes
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@swap

# Verify subvolumes were created
btrfs subvolume list /mnt

# Unmount the partition
umount /mnt
```

### Subvolume Purpose:

-   `@` → Root filesystem
-   `@home` → User home directories
-   `@log` → System logs (`/var/log`)
-   `@pkg` → Package cache (`/var/cache/pacman/pkg`)
-   `@swap` → Swap file location

## Step 5: Mount Subvolumes with Optimized Options

### Mount root subvolume first:

```bash
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@ /dev/nvme0n1p6 /mnt
```

### Create mount point directories:

```bash
mkdir -p /mnt/{boot,home,var/log,var/cache/pacman/pkg,swap}
```

### Mount remaining subvolumes:

```bash
# Mount home
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@home /dev/nvme0n1p6 /mnt/home

# Mount log
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@log /dev/nvme0n1p6 /mnt/var/log

# Mount package cache
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@pkg /dev/nvme0n1p6 /mnt/var/cache/pacman/pkg

# Mount swap (no compression for swap)
mount -o noatime,ssd,space_cache=v2,discard=async,subvol=@swap /dev/nvme0n1p6 /mnt/swap

# Mount EFI partition
mount /dev/nvme0n1p5 /mnt/boot
```

### Verify mount structure:

```bash
lsblk -f
# or
mount | grep /mnt
```

## Step 6: Install Base System

### Update package databases and install prerequisites:

```bash
# Refresh package databases
pacman -Sy

# Update archlinux-keyring to avoid signature issues
pacman -S archlinux-keyring

# Install archinstall (if not already available)
pacman -S archinstall
```

## Step 7: Run Archinstall with Preconfigured Mounts

```bash
archinstall
```

### In the archinstall menu:

1. **Disk configuration**: Select `Use existing mount points`
2. **Mount point**: Enter `/mnt` when prompted
3. Configure the following as needed:

    - **Bootloader**: systemd-boot (recommended for UEFI)
    - **Hostname**: Your desired hostname
    - **Root password**: Set a strong password
    - **User account**: Create your user
    - **Profile**: Desktop, minimal, or custom
    - **Audio**: pipewire (recommended)
    - **Kernels**: linux (or linux-lts for stability)
    - **Network configuration**: NetworkManager or iwd
    - **Timezone**: Your timezone
    - **Additional packages**: Add any you need (e.g., `vim`, `git`, `firefox`)

4. Review and confirm installation
5. Install!

## Mount Options Explained

-   `noatime` → Don't update access times (improves performance)
-   `ssd` → Enable SSD optimizations
-   `compress=zstd` → Enable transparent compression (better than lzo/zlib)
-   `space_cache=v2` → Improved free space cache (faster mounting)
-   `discard=async` → Async TRIM support (better for SSD lifespan)
-   `subvol=@` → Specify which subvolume to mount

## Post-Installation: Creating a Swap File (Optional)

After installation and first boot:

```bash
# Navigate to swap subvolume
cd /swap

# Create a swap file (adjust size as needed, e.g., 8G)
sudo btrfs filesystem mkswapfile --size 8G swapfile

# Enable the swap file
sudo swapon /swap/swapfile

# Make it permanent
echo '/swap/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab
```

⚠️ **Note**: Do NOT use `dd` or `fallocate` to create swap files on Btrfs. Use the `btrfs filesystem mkswapfile` command instead.

## Verification Checklist

After installation completes:

```bash
# Check mounted filesystems
df -h

# Verify Btrfs subvolumes
sudo btrfs subvolume list /

# Check bootloader installation
bootctl status  # For systemd-boot
```
