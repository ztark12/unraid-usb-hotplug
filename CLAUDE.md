# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

USB Hotplug Plugin for Unraid - Provides automatic USB device management for Unraid VMs with real-time hotplug support. The plugin allows USB devices to be automatically attached when VMs start and dynamically added/removed as devices are plugged/unplugged.

**Current Version:** 2025.02.17b

## Build and Deployment

### Building the Plugin Package

```bash
./build-plugin.sh
```

This creates `build/usb-hotplug-<VERSION>.txz` containing all plugin files in the correct directory structure for Unraid installation.

### Version Management

**Version Naming Convention:**
- Format: `YYYY.MM.DD[a-z]`
- Date represents the release date
- Letter suffix (a, b, c, etc.) for multiple releases on same day
- Examples: `2025.02.11a` (first release), `2025.02.11b` (second release same day)
- Increment letter for bug fixes or minor updates on same day
- Use next date for new feature releases

**IMPORTANT:** Version number must be updated in THREE places when releasing:
1. `build-plugin.sh` - Line 8: `VERSION="2025.02.11b"`
2. `usb-hotplug.plg` - Line 5: `<!ENTITY version   "2025.02.11b">`
3. `CLAUDE.md` - Line 9: `**Current Version:** 2025.02.17b`

### GitHub Release Process

1. Build package: `./build-plugin.sh`
2. Create GitHub release with tag `v<VERSION>`
3. Upload the `.txz` file to the release
4. Update CHANGES section in `usb-hotplug.plg`
5. Commit and push to main branch

Users install via: `https://raw.githubusercontent.com/ztark12/unraid-usb-hotplug/main/usb-hotplug.plg`

## Architecture

The plugin consists of three main components that work together:

### 1. VM Monitor (`qemu-vm-monitor.sh`)
- Background daemon that polls for VM state changes every 2 seconds
- Detects when VMs start and automatically attaches all non-blacklisted USB devices
- Loads device blacklist from `/boot/config/plugins/usb-hotplug/usb-hotplug.cfg`
- Implements crash protection with error recovery (exits after 10 consecutive virsh failures)
- Started automatically on plugin install and survives reboots

### 2. Hotplug Handler (`qemu-usb-hotplug.sh`)
- Triggered by udev rules when USB devices are added/removed
- **Add action**: Scans for new device, avoids duplicates, attaches to running VM
- **Remove action**: Finds and cleans up stale device references in VM XML
- Uses temporary XML files for virsh attach/detach operations
- Implements retry logic (up to 10 attempts with 200ms sleep) for device detection

### 3. Web UI (`USBHotplug.page`)
- PHP page integrated into Unraid Settings menu
- Displays monitor status, connected devices, and logs
- Blacklist editor with CSRF token protection
- Line ending normalization (converts CRLF → LF for bash compatibility)
- Control buttons: restart/stop monitor, clear logs, save blacklist

### Component Interaction Flow

```
User plugs USB device
  → udev rule triggers → qemu-usb-hotplug-call.sh (random delay wrapper)
    → qemu-usb-hotplug.sh (add action)
      → Finds device in /sys/bus/usb/devices/
      → Creates XML definition
      → virsh attach-device to running VM

VM starts
  → qemu-vm-monitor.sh detects state change
    → Loads blacklist from config file
    → Scans /sys/bus/usb/devices/ for all devices
    → Skips: USB hubs (class 09), blacklisted devices, already-attached
    → Attaches remaining devices via virsh
```

## Key Technical Details

### Boot Drive Protection (CRITICAL SAFETY FEATURE)
- **Auto-detection**: Monitor automatically detects the Unraid boot drive on startup
- **Automatic blacklisting**: Boot drive is always added to blacklist, even if not in config
- **Why this matters**: Prevents catastrophic system crash if boot drive is accidentally attached to VM
- **Detection method**:
  1. Finds device mounted at `/boot` via `mount` command
  2. Traces block device to USB parent via `/sys/block/*/device`
  3. Reads vendor:product ID from `/sys/bus/usb/devices/*/idVendor` and `idProduct`
  4. Adds to runtime blacklist if not already present
- **Fallback**: If detection fails, logs warning but continues (relies on config file)
- **Health check**: Monitor verifies `/boot` is accessible on startup (exits if not)

### Blacklist Format
- Config file: `/boot/config/plugins/usb-hotplug/usb-hotplug.cfg`
- Format: `VENDOR_ID:PRODUCT_ID  # Optional comment`
- Regex validation: `^[0-9a-fA-F]{4}:[0-9a-fA-F]{4}$`
- Monitor reloads blacklist on each VM start (allows runtime updates)
- **Boot drive is ALWAYS protected** regardless of config content (auto-detected)

### Device Identification
- Devices identified by bus:device numbers (not vendor:product) for attach/detach
- Multiple identical devices supported (different bus:device but same vendor:product)
- Device state changes (e.g., 8BitDo IDLE→Active) handled as remove→add sequence

### Udev Rules (`99-qemu-usb-hotplug.rules`)
- Only triggers for `usb_device` type (not interfaces)
- Excludes USB hubs via `ATTR{bDeviceClass}!="09"`
- Uses wrapper script `qemu-usb-hotplug-call.sh` with random delay to prevent race conditions

### Error Handling
- All virsh commands wrapped with `timeout` (2-5 seconds)
- Stale device cleanup: detects devices in VM XML that no longer exist in lsusb
- Monitor restarts automatically via web UI when blacklist is saved
- Failed attachments logged but don't crash monitor

## Directory Structure

```
build/package/                              # Build output (created by build-plugin.sh)
  ├── usr/local/sbin/                       # Runtime scripts
  │   ├── qemu-vm-monitor.sh               # VM monitoring daemon
  │   ├── qemu-usb-hotplug.sh              # Hotplug handler
  │   └── qemu-usb-hotplug-call.sh         # Wrapper with random delay
  ├── etc/udev/rules.d/                     # System integration
  │   └── 99-qemu-usb-hotplug.rules        # USB event triggers
  ├── usr/local/emhttp/plugins/usb-hotplug/ # Web UI
  │   └── USBHotplug.page                  # Settings page (PHP)
  └── boot/config/plugins/usb-hotplug/     # Persistent config
      └── usb-hotplug.cfg                  # Device blacklist

Source files (repository root):
  ├── build-plugin.sh          # Build script (creates .txz package)
  ├── usb-hotplug.plg          # Unraid plugin definition (XML)
  ├── qemu-vm-monitor.sh       # Source for monitor daemon
  ├── USBHotplug.page          # Source for web UI
  └── README.md                # User documentation
```

## Testing

See `TESTING.md` for comprehensive test checklist. Key test scenarios:

- VM startup with devices already connected
- Hotplug add/remove during VM runtime
- Multiple identical devices (same vendor:product ID)
- Device state changes (8BitDo controller IDLE↔Active mode)
- Blacklist modifications via web UI
- Monitor crash recovery
- Persistence across reboots

Manual testing guide: `MANUAL-TESTING-GUIDE.md`

## Known Behaviors

- USB hubs (class 09) are always excluded, even if not blacklisted
- First running VM gets all devices (no multi-VM distribution)
- Devices attach within ~2 seconds of plug event
- VM startup attachment takes ~10 seconds (intentional delay for VM stabilization)
- Monitor must be restarted to apply blacklist changes (web UI does this automatically)
- Config file must end with newline for bash `read` to work correctly (web UI ensures this)

## Line Ending Handling

Web UI normalizes all line endings to Unix LF format:
- Handles Windows CRLF (`\r\n`) and Mac CR (`\r`)
- Ensures config file ends with newline (required for bash `while read`)
- Critical for cross-platform compatibility when users edit via web UI

## CSRF Protection

All POST forms include: `<input type="hidden" name="csrf_token" value="<?= $var['csrf_token'] ?>">`

This is required for Unraid web UI form submissions to work properly.
