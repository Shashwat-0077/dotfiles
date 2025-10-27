#!/bin/bash

set -e  # Exit on error


echo "Unblocking WiFi..."
sudo rfkill unblock all

echo "Starting iwd service..."
sudo systemctl start iwd.service

echo "Running iwctl commands..."
iwctl <<EOF
device list
station wlan0 set-property Powered on
station wlan0 scan
station wlan0 get-networks
EOF
