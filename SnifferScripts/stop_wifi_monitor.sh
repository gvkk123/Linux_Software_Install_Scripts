#!/bin/bash

# -------- Configuration --------
DEFAULT_MON_DEV="wlan0mon"
MON_DEV="${1:-$DEFAULT_MON_DEV}"
DEV="${MON_DEV%mon}"

# Stop monitor mode
echo "[*] Stopping monitor mode on $MON_DEV..."
sudo airmon-ng stop "$MON_DEV"

# Restart network services
echo "[*] Restarting NetworkManager..."
sudo systemctl restart NetworkManager

sleep 2

# Show final status
echo "[*] Verifying interface state..."
iw dev $DEV info


echo "[✓] Monitor mode stopped"
echo "[✓] $DEV interface restored to managed mode"
