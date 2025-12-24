# Arch Linux Secure Boot Setup with sbctl

## Prerequisites

⚠️ **CRITICAL FIRST STEP**: Before starting, you must enter your BIOS/UEFI firmware and:

1. Enter **Setup Mode** for Secure Boot (sometimes called "Clear Secure Boot keys" or "Reset to Setup Mode")
2. **Do NOT enable Secure Boot yet** - keep it disabled during setup
3. Save and exit BIOS

Without entering Setup Mode first, you cannot enroll custom keys and this process will fail.

## Important Notes

-   ✅ **systemd-boot**: This guide is tested and works with systemd-boot bootloader
-   ❌ **GRUB**: May require additional configuration (not covered here)
-   🪟 **Dual-boot with Windows**: The `-m` flag preserves Microsoft keys for Windows compatibility

## Step 1: Install sbctl

```bash
# Update package database and install sbctl
sudo pacman -Sy sbctl
```

## Step 2: Switch to Root User

```bash
# Enter root shell
sudo -i
```

All following commands should be run as root.

## Step 3: Check Current Status

```bash
# Check Secure Boot status
sbctl status
```

**Expected output**:

-   Installed: ✓ systemd-boot
-   Setup Mode: ✓ Enabled (if you entered Setup Mode in BIOS)
-   Secure Boot: ✗ Disabled

If "Setup Mode" shows as disabled, return to BIOS and clear Secure Boot keys.

## Step 4: Create Custom Keys

```bash
# Generate custom Secure Boot keys
sbctl create-keys
```

This creates your own Platform Key (PK), Key Exchange Key (KEK), and Database (db) keys in `/usr/share/secureboot/`.

## Step 5: Enroll Keys

```bash
# Enroll keys with Microsoft keys included
sbctl enroll-keys -m
```

**Flag explanation**:

-   `-m` or `--microsoft`: Include Microsoft's keys alongside your custom keys
-   **Required for dual-boot**: Without this, Windows will not boot
-   **Required for some hardware**: Some UEFI firmware and hardware require Microsoft signatures

**Expected output**: Keys enrolled successfully

## Step 6: Sign the Bootloader

```bash
# Sign the systemd-boot bootloader
sbctl sign -s /usr/lib/systemd/boot/efi/systemd-bootx64.efi
```

**Flag explanation**:

-   `-s` or `--save`: Saves the file to the database for automatic re-signing during updates

## Step 7: Identify Files That Need Signing

```bash
# Check what needs to be signed
sbctl verify
```

**Common files that need signing**:

-   `/boot/vmlinuz-linux` (kernel)
-   `/boot/vmlinuz-linux-lts` (LTS kernel, if installed)
-   `/boot/EFI/BOOT/BOOTX64.EFI` (fallback bootloader)
-   `/boot/EFI/systemd/systemd-bootx64.efi` (systemd-boot)
-   `/usr/lib/fwupd/efi/fwupdx64.efi` (firmware updater, if installed)

## Step 8: Sign All Required Files

Sign each file listed by `sbctl verify` with a ✗ symbol:

```bash
# Sign the Linux kernel
sbctl sign -s /boot/vmlinuz-linux

# Sign LTS kernel (if you have it installed)
sbctl sign -s /boot/vmlinuz-linux-lts

# Sign fallback bootloader
sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI

# Sign systemd-boot (in boot partition)
sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi

# Sign firmware updater (if present)
sbctl sign -s /usr/lib/fwupd/efi/fwupdx64.efi
```

**Important**: Always use the `-s` flag to save files to the database for automatic re-signing.

## Step 9: Verify All Files Are Signed

```bash
# Verify everything is signed
sbctl verify
```

**Expected output**: All files should show ✓ Signed

If any files still show ✗, sign them using the command from Step 8.

## Step 10: Reinstall Bootloader

```bash
# Reinstall systemd-boot to boot partition
bootctl install
```

This ensures the signed bootloader is properly installed.

## Step 11: Exit Root and Reboot

```bash
# Exit root shell
exit

# Reboot the system
reboot
```

## Step 12: Enable Secure Boot in BIOS

1. Enter BIOS/UEFI firmware settings
2. Navigate to Secure Boot settings
3. **Enable Secure Boot**
4. Save and exit

Your system should now boot with Secure Boot enabled!

## Verification After Reboot

```bash
# Check Secure Boot status
sudo sbctl status
```

**Expected output**:

-   Installed: ✓ systemd-boot
-   Setup Mode: ✗ Disabled
-   Secure Boot: ✓ **Enabled**

## Automatic Re-signing on Updates

sbctl includes a pacman hook that automatically re-signs files when they're updated. Verify it's working:

```bash
# Check for sbctl pacman hook
cat /usr/share/libalpm/hooks/zz-sbctl.hook
```

This hook ensures your kernel and bootloader remain signed after system updates.

## Troubleshooting

### System won't boot after enabling Secure Boot

1. Boot into BIOS and disable Secure Boot
2. Boot into Arch Linux
3. Run `sudo sbctl verify` to check what's unsigned
4. Sign any missing files
5. Run `sudo bootctl install`
6. Re-enable Secure Boot

### "Verification failed" errors

```bash
# Clear old signatures and re-sign
sudo sbctl sign -s -f /path/to/file
```

The `-f` flag forces re-signing even if already signed.

### Windows won't boot

-   Ensure you used the `-m` flag when enrolling keys
-   Try re-enrolling keys: `sudo sbctl enroll-keys -m`

### Checking what's currently signed

```bash
# List all files in sbctl database
sudo sbctl list-files
```

## Updating the Kernel

When the kernel updates, sbctl automatically re-signs it. But if you encounter issues:

```bash
# Manually re-sign kernel after update
sudo sbctl sign -s /boot/vmlinuz-linux

# Verify signature
sudo sbctl verify
```

## Removing Secure Boot (If Needed)

If you need to disable Secure Boot later:

1. Disable Secure Boot in BIOS
2. Optionally remove keys: `sudo sbctl enroll-keys --clear`

## Additional Security Tips

-   **Keep keys backed up**: Your keys are in `/usr/share/secureboot/` - back them up securely
-   **Don't share keys**: Your private keys should never be shared or committed to version control
-   **Monitor updates**: Check `sbctl verify` occasionally to ensure everything remains signed
-   **Use TPM**: Consider using TPM-based full disk encryption for additional security

## Benefits of Secure Boot

✅ **Prevents rootkits**: Malware can't modify the bootloader or kernel  
✅ **Verified boot chain**: Only signed code runs during boot  
✅ **Hardware firmware protection**: Some features require Secure Boot  
✅ **Peace of mind**: Know your system hasn't been tampered with
