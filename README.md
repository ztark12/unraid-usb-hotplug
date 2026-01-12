# USB Hotplug Plugin for Unraid

Automatic USB device management for Unraid VMs with real-time hotplug support.

**Version: 2025.01.12a** - Tested and working!

## What's New in v2025.01.12a

✅ **Fixed CSRF Token Support** - All forms now work properly (Save Blacklist button functional!)  
✅ **Improved Config Format** - Removed confusing example line from default blacklist  
✅ **Better User Feedback** - Success/error messages display correctly  
✅ **Production Ready** - Fully tested on Unraid 6.12.x  

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
