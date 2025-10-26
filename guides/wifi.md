# Arch Linux WiFi Setup Guide

## Initial Connection (Installation Environment)

```bash
# Unblock WiFi devices
rfkill unblock all

# Launch iwd interactive prompt
iwctl

# Inside iwctl prompt:
device list                              # List available devices
station wlan0 set-property Powered on   # Power on the WiFi adapter
station wlan0 scan                       # Scan for networks
station wlan0 get-networks               # Display available networks
station wlan0 connect "Your Network Name"  # Connect to network
exit                                     # Exit iwctl
```

## Post-Installation Configuration

### 1. Enable and Start iwd Service

```bash
# Check service status
systemctl status iwd.service

# Start iwd immediately
sudo systemctl start iwd.service

# Enable iwd to start automatically at boot
sudo systemctl enable iwd.service
```

### 2. Configure NetworkManager to Use iwd Backend (Optional)

If you're using NetworkManager, configure it to use iwd:

```bash
# Create configuration directory if needed
sudo mkdir -p /etc/NetworkManager/conf.d/

# Create the backend configuration file
sudo nvim /etc/NetworkManager/conf.d/wifi_backend.conf
```

Add the following content:

```ini
[device]
wifi.backend=iwd
```

Then restart NetworkManager:

```bash
sudo systemctl restart NetworkManager
```

### 3. Configure DNS Resolution

```bash
# Enable and start systemd-resolved
sudo systemctl enable systemd-resolved.service
sudo systemctl start systemd-resolved.service

# Create symlink for DNS resolution
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Restart iwd to apply changes
sudo systemctl restart iwd.service
```

## Troubleshooting: If WiFi Still Doesn't Work

If you're still experiencing connection issues, configure iwd for automatic network management:

```bash
# Create iwd configuration directory
sudo mkdir -p /etc/iwd

# Create main configuration file
sudo tee /etc/iwd/main.conf > /dev/null <<EOF
[General]
EnableNetworkConfiguration=true

[Network]
NameResolvingService=systemd
EOF

# Restart services to apply configuration
sudo systemctl restart iwd
sudo systemctl restart systemd-resolved
```

## Verification

Check if you're connected:

```bash
# Check IP address
ip addr show wlan0

# Test connectivity
ping -c 4 archlinux.org

# Check DNS resolution
resolvectl status
```

## Common Issues

-   **No networks found**: Ensure WiFi isn't blocked with `rfkill list`
-   **Connection drops**: Check power management settings in `/etc/iwd/main.conf`
-   **DNS not working**: Verify `systemd-resolved` is running and `/etc/resolv.conf` symlink is correct
-   **Slow connection**: Try disabling NetworkManager's internal DHCP and let iwd handle it

## Notes

-   Replace `wlan0` with your actual WiFi interface name (check with `ip link`)
-   Replace `"Your Network Name"` with your actual network SSID
-   For hidden networks, use: `iwctl station wlan0 connect-hidden "Network Name"`
-   To forget a network: `iwctl known-networks list` then `iwctl known-networks "Network Name" forget`
