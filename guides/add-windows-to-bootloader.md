# Adding Windows 11 to systemd-boot

This guide walks you through adding a Windows 11 entry to your systemd-boot bootloader on a Linux system.

## Prerequisites

-   Root/sudo access
-   systemd-boot already installed
-   Windows 11 installed on a separate EFI partition

## Step 1: Locate the Windows EFI Partition

First, identify your Windows EFI partition:

```bash
lsblk -f
```

Look for a partition labeled "EFI" or with a FAT32 filesystem. Common locations:

-   `/dev/nvme0n1p1` (NVMe drives)
-   `/dev/sda1` (SATA drives)

## Step 2: Mount the Windows EFI Partition

Create a temporary mount point and mount the partition:

```bash
sudo mkdir -p /mnt/windows-efi
sudo mount /dev/nvme0n1p1 /mnt/windows-efi
```

**Replace `/dev/nvme0n1p1` with your actual Windows EFI partition.**

## Step 3: Verify Windows Boot Files

Check that the Microsoft boot files exist:

```bash
ls /mnt/windows-efi/EFI
ls /mnt/windows-efi/EFI/Microsoft
```

You should see folders like `Boot` and `Recovery`.

## Step 4: Copy Microsoft Boot Files

Copy the Windows boot files to your Linux EFI partition:

```bash
sudo cp -r /mnt/windows-efi/EFI/Microsoft /boot/EFI/
```

**Note:** Some systems use `/boot/efi` instead of `/boot/EFI`. Adjust accordingly.

## Step 5: Get the Windows Partition UUID

Retrieve the PARTUUID of your Windows EFI partition:

```bash
sudo blkid /dev/nvme0n1p1
```

Copy the `PARTUUID` value (e.g., `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`).

## Step 6: Create Boot Entry Configuration

Create a new boot entry file:

```bash
sudo nvim /boot/loader/entries/windows.conf
```

Add the following content:

```
title   Windows 11
efi     /EFI/Microsoft/Boot/bootmgfw.efi
options PARTUUID=YOUR-PARTUUID-HERE
```

**Important:** Replace `YOUR-PARTUUID-HERE` with the actual PARTUUID from Step 5.

### Alternative Format

Some configurations may require:

```
title   Windows 11
efi     /EFI/Microsoft/Boot/bootmgfw.efi
device  PARTUUID=YOUR-PARTUUID-HERE
```

## Step 7: Unmount and Update

Unmount the Windows partition and update the bootloader:

```bash
sudo umount /mnt/windows-efi
sudo bootctl update
```

## Step 8: Verify Installation

Check that your entry was added successfully:

```bash
sudo bootctl list
```

You should see "Windows 11" in the list of boot entries.

## Troubleshooting

**Boot entry doesn't appear:**

-   Verify the path `/EFI/Microsoft/Boot/bootmgfw.efi` exists in `/boot/EFI/`
-   Check that you're using the correct PARTUUID
-   Try using `options` instead of `device` (or vice versa)

**Windows won't boot:**

-   Ensure Secure Boot is configured correctly in BIOS/UEFI
-   Verify the Microsoft boot files were copied completely
-   Check BIOS boot order settings

**Permission denied errors:**

-   Ensure you're using `sudo` for all commands
-   Verify your user has sudo privileges

## Notes

-   This process doesn't modify your Windows installation
-   You can safely delete the Windows entry by removing the `.conf` file
-   Keep the Microsoft folder in `/boot/EFI/` for the entry to work
-   On some distributions, the EFI path may be `/efi` or `/boot/efi` instead of `/boot/EFI`
