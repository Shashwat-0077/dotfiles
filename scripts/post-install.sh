#!/bin/bash

set -e  # Exit on error

SWAP_SIZE="8G"
SWAP_PATH="/swap/swapfile"

echo "Creating swap directory if not exists..."
sudo mkdir -p /swap

cd /swap

echo "Creating Btrfs swapfile of size $SWAP_SIZE ..."
sudo btrfs filesystem mkswapfile --size $SWAP_SIZE swapfile

echo "Enabling swap..."
sudo swapon $SWAP_PATH

echo "Adding swap to /etc/fstab if not already present..."
if ! grep -q "$SWAP_PATH" /etc/fstab; then
    echo "$SWAP_PATH none swap defaults 0 0" | sudo tee -a /etc/fstab > /dev/null
    echo "Swap entry added to fstab."
else
    echo "Swap entry already exists in fstab, skipping."
fi

echo "Installing systemd-boot..."
sudo bootctl install

echo "Done."
