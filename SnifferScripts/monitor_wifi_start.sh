#!/bin/bash

# -------- Default Values --------
DEFAULT_CHANNEL="36"
DEFAULT_BANDWIDTH="80MHz"
DEFAULT_DEV="wlan0"

# -------- Read Inputs or Use Defaults --------
CHANNEL_INPUT="${1:-$DEFAULT_CHANNEL}"
BANDWIDTH="${2:-$DEFAULT_BANDWIDTH}"
DEV="${3:-$DEFAULT_DEV}"
MON_DEV="${DEV}mon"

# -------- Configuration --------

echo "[*] Using configuration:"
echo "    Interface : $DEV"
echo "    Channel   : $CHANNEL_INPUT"
echo "    Bandwidth : $BANDWIDTH"

# -------- Interface Info --------
ifconfig "$DEV"
iwconfig "$DEV"
sudo iw dev "$DEV" info

echo "[*] Scanning (managed mode only)..."
sudo iw dev "$DEV" scan | grep -E "freq:|SSID:"
# -------- Sanity Checks --------
# sudo apt install aircrack-ng iw wireshark tshark net-tools kismet

# -------- Start Monitor Mode --------

sudo airmon-ng --verbose

echo "[*] Killing interfering processes..."
sudo airmon-ng check kill

echo "[*] Starting monitor mode on $DEV..."
sudo airmon-ng start "$DEV"

sleep 2
echo "[*] Monitor interface: $MON_DEV"

# -------- Set Regulatory Domain --------
echo "[*] Setting regulatory domain to US..."
sudo iw reg set US
iw reg get

# -------- Channel / Frequency Handling --------
if [[ "$CHANNEL_INPUT" =~ e$ ]]; then
    # -------- 6 GHz --------
    CHANNEL_NUM="${CHANNEL_INPUT%e}"
    CENTER_FREQ=$((5950 + 5 * CHANNEL_NUM))

    echo "[*] Detected 6 GHz channel"
    echo "[*] Channel number   : $CHANNEL_NUM"
    echo "[*] Center frequency : ${CENTER_FREQ} MHz"

    sudo iw dev "$MON_DEV" set freq "$CENTER_FREQ" "$BANDWIDTH" || {
        echo "[-] Failed to set channel"
        exit 1
    }

    #echo "[*] Starting airodump-ng (6 GHz fixed frequency)..."
    #sudo airodump-ng "$MON_DEV" -C "$CENTER_FREQ"

else
    # -------- 2.4 / 5 GHz --------
    echo "[*] Detected 2.4 / 5 GHz channel"
    echo "[*] Channel number   : $CHANNEL_INPUT"

    sudo iw dev "$MON_DEV" set channel "$CHANNEL_INPUT" "$BANDWIDTH" || {
        echo "[-] Failed to set channel"
        exit 1
    }

    #echo "[*] Starting airodump-ng (fixed channel)..."
    #sudo airodump-ng "$MON_DEV" -c "$CHANNEL_INPUT"
fi

# -------- Launch Kismet --------
#echo "[*] Starting Kismet (channel locked)..."
#sudo kismet -c "${MON_DEV}:channels=${CHANNEL},channel_hop=false" &

sleep 2

# -------- Launch Wireshark --------
sudo iw dev "$MON_DEV" info
echo "[*] Starting Wireshark..."
sudo wireshark -i "$MON_DEV" -k &

echo "[✓] Monitor mode active"
echo "[✓] Wireshark running on $MON_DEV"
