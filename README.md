# USB Hotplug Plugin for Unraid

Automatic USB device management for Unraid VMs with real-time hotplug support.

**Version: 2025.02.11a** - Critical Boot Drive Protection Update!

## What's New in v2025.02.11a

🔥 **CRITICAL FIX: Auto-Detect Boot Drive** - Monitor now automatically detects and protects your boot drive
🛡️ **Prevents System Crashes** - No more catastrophic failures if boot drive changes
✅ **Boot Drive Health Check** - Monitor verifies boot drive accessibility on startup
✅ **Config Validation** - Detects corrupted config files before they cause issues
🔒 **Always Protected** - Boot drive is blacklisted even if not in config file  

## Features

✅ **Automatic USB Attachment** - All non-blacklisted USB devices automatically attach when VMs start  
✅ **Real-time Hotplug** - Plug/unplug devices anytime and they instantly appear/disappear in running VMs  
✅ **State Change Handling** - Handles devices that change modes (e.g., 8BitDo controllers: IDLE ↔ Active)  
✅ **Multiple Identical Devices** - Supports multiple USB devices with the same vendor/product ID  
✅ **Automatic Cleanup** - Removes stale device references automatically  
✅ **Web UI Configuration** - Easy blacklist management via Unraid Settings  
✅ **Crash Protection** - Built-in error recovery and monitoring  
✅ **Persistent Configuration** - Survives reboots and Unraid updates  

## Quick Start

1. Install the plugin
2. Go to **Settings → USB Hotplug**
3. Edit blacklist if needed
4. Start your VM - USB devices attach automatically!

For detailed installation instructions, see below.

## Installation

### Via GitHub (Recommended for Testing)

1. Go to **Plugins** tab in Unraid
2. Click **Install Plugin** at the bottom
3. Paste: `https://raw.githubusercontent.com/YOUR_USERNAME/unraid-usb-hotplug/master/usb-hotplug.plg`
4. Click **Install**

### Manual Installation

See [MANUAL-TESTING-GUIDE.md](MANUAL-TESTING-GUIDE.md) for step-by-step manual installation.

## Configuration

Access via: **Settings → USB Hotplug**

### Blacklist Format
```
VENDOR_ID:PRODUCT_ID  # Optional comment
```

### Example
```
18a5:0302  # Unraid flash drive
0b05:19af  # ASUS AURA LED Controller
8087:0033  # Intel Bluetooth
```

⚠️ **Important:** No example lines with device IDs in comments!

## Usage

The plugin works automatically:
- Start VM → Devices auto-attach
- Plug device → Appears in VM instantly
- Unplug device → Removed cleanly

## ⚠️ CRITICAL: Boot Drive Changes

**If you change your Unraid USB boot drive, read this IMMEDIATELY:**

### The Problem
The plugin auto-detects and protects your boot drive from being attached to VMs. However, if you're upgrading from an older version (before v2025.01.12d), you may need to manually add your boot drive to the blacklist.

### Symptoms of Boot Drive Not Protected
- Server crashes completely when starting a VM
- Error message: "boot drive is corrupted"
- System becomes unresponsive (requires physical reboot)
- Web UI stops responding after VM starts

### Emergency Fix (If System is Crashing)

**Do this BEFORE starting any VMs:**

```bash
# 1. SSH into your Unraid server

# 2. Find your boot drive's vendor:product ID
mount | grep /boot
# Note the device (e.g., /dev/sdb1)

lsusb
# Find your flash drive brand (Kingston, SanDisk, etc.)
# Note the ID in format XXXX:XXXX

# 3. Add your boot drive to the blacklist
# REPLACE 0951:1666 with YOUR ACTUAL boot drive ID!
cat >> /boot/config/plugins/usb-hotplug/usb-hotplug.cfg << 'EOF'
0951:1666  # My boot drive - REPLACE THIS ID!
EOF

# 4. Restart the monitor
pkill -f qemu-vm-monitor.sh
nohup /usr/local/sbin/qemu-vm-monitor.sh > /dev/null 2>&1 &

# 5. Verify boot drive is protected
tail -20 /var/log/usb-hotplug.log
# Should show: "Boot drive detected and protected: XXXX:XXXX"
```

### Why This Happens
When you change boot drives, the new drive has a different vendor:product ID. The plugin now **automatically detects and protects your boot drive**, but older versions relied on manual blacklist configuration.

### Prevention
✅ **v2025.02.11a and newer** - Boot drive is automatically detected and protected
⚠️ **Older versions** - Must manually add boot drive to blacklist after changing USB drives

## Troubleshooting

### Common Issues

**Save Blacklist not working?**
- Fixed in v2025.01.12a! Update if using older version.

**Devices not attaching?**
```bash
# Check monitor
ps aux | grep qemu-vm-monitor

# Check logs
tail -f /var/log/usb-hotplug.log
```

**Wrong device count?**
- Remove any example lines with device IDs from config
- Ensure format is exactly: `XXXX:XXXX` (no extra characters)

## Documentation

- [README.md](README.md) - You are here
- [DEPLOYMENT.md](DEPLOYMENT.md) - How to publish to GitHub
- [MANUAL-TESTING-GUIDE.md](MANUAL-TESTING-GUIDE.md) - Manual installation
- [TESTING.md](TESTING.md) - Full testing checklist
- [QUICKSTART.md](QUICKSTART.md) - Quick reference

## Support

- **GitHub Issues**: Report bugs and request features
- **Unraid Forums**: Community support
- **Documentation**: Comprehensive guides included

## License

MIT License - Free and open source

## Changelog

### v2025.01.12a (Latest)
- Fixed CSRF token support
- Improved config format
- Better user feedback
- Production ready

### v2025.01.12
- Initial release
- Core functionality
- Web UI
- Blacklist management

---

**Tested and working on Unraid 6.12.x** ✅
