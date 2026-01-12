# Manual Plugin Installation for Testing

This guide shows how to install and test the USB Hotplug plugin without GitHub.

## Method 1: Direct Installation (Recommended for Testing)

### Step 1: Build the Package

On your local machine or Unraid server:

```bash
# Navigate to the plugin directory
cd /path/to/usb-hotplug-plugin

# Run the build script
chmod +x build-plugin.sh
./build-plugin.sh
```

This creates: `build/usb-hotplug-2025.01.12.txz`

### Step 2: Upload Package to Unraid

Transfer the .txz file to your Unraid server:

**Option A - Using Unraid Web Interface:**
1. Go to **Main** tab in Unraid
2. Click on your **flash drive** (usually /boot)
3. Navigate to or create: `config/plugins/usb-hotplug/`
4. Upload `usb-hotplug-2025.01.12.txz` there

**Option B - Using SCP/SFTP:**
```bash
scp build/usb-hotplug-2025.01.12.txz root@your-unraid-ip:/boot/config/plugins/usb-hotplug/
```

**Option C - Using Unraid terminal:**
```bash
# If you built on Unraid, just copy it
mkdir -p /boot/config/plugins/usb-hotplug
cp build/usb-hotplug-2025.01.12.txz /boot/config/plugins/usb-hotplug/
```

### Step 3: Extract and Install

SSH into your Unraid server and run:

```bash
# Extract the package
cd /
tar -xf /boot/config/plugins/usb-hotplug/usb-hotplug-2025.01.12.txz

# Make scripts executable
chmod +x /usr/local/sbin/qemu-usb-hotplug.sh
chmod +x /usr/local/sbin/qemu-usb-hotplug-call.sh
chmod +x /usr/local/sbin/qemu-vm-monitor.sh

# Reload udev rules
udevadm control --reload-rules

# Create log file
touch /var/log/usb-hotplug.log
chmod 644 /var/log/usb-hotplug.log

# Create default config if it doesn't exist
if [ ! -f /boot/config/plugins/usb-hotplug/usb-hotplug.cfg ]; then
    cat > /boot/config/plugins/usb-hotplug/usb-hotplug.cfg << 'EOF'
# USB Hotplug Blacklist Configuration
# Format: VENDOR_ID:PRODUCT_ID  # Description

18a5:0302  # Unraid flash drive
EOF
fi

# Start the monitor
nohup /usr/local/sbin/qemu-vm-monitor.sh > /dev/null 2>&1 &
```

### Step 4: Verify Installation

```bash
# Check if monitor is running
ps aux | grep qemu-vm-monitor

# Check if web UI file is in place
ls -l /usr/local/emhttp/plugins/usb-hotplug/

# View logs
tail -f /var/log/usb-hotplug.log
```

### Step 5: Access Web UI

1. Open Unraid web interface
2. Go to **Settings**
3. Look for **USB Hotplug** in the sidebar

If the Settings page doesn't appear, refresh the page or restart the web server:
```bash
/etc/rc.d/rc.nginx restart
```

## Method 2: Simple Script Installation (No Build Required)

If you just want to test quickly without building the package:

```bash
# SSH into Unraid
ssh root@your-unraid-ip

# Create directories
mkdir -p /boot/config/plugins/usb-hotplug
mkdir -p /usr/local/emhttp/plugins/usb-hotplug

# Copy your scripts (you'll need to upload them first)
# Assuming you've uploaded them to /tmp/

cp /tmp/qemu-usb-hotplug.sh /usr/local/sbin/
cp /tmp/qemu-usb-hotplug-call.sh /usr/local/sbin/
cp /tmp/qemu-vm-monitor.sh /usr/local/sbin/
cp /tmp/99-qemu-usb-hotplug.rules /etc/udev/rules.d/
cp /tmp/USBHotplug.page /usr/local/emhttp/plugins/usb-hotplug/

# Make scripts executable
chmod +x /usr/local/sbin/qemu-usb-hotplug*.sh
chmod +x /usr/local/sbin/qemu-vm-monitor.sh

# Create default config
cat > /boot/config/plugins/usb-hotplug/usb-hotplug.cfg << 'EOF'
18a5:0302  # Unraid flash drive
EOF

# Reload udev and start
udevadm control --reload-rules
touch /var/log/usb-hotplug.log
nohup /usr/local/sbin/qemu-vm-monitor.sh > /dev/null 2>&1 &
```

## Method 3: Test with Modified .plg File (Most Realistic)

This simulates the actual plugin installation:

### Step 1: Prepare Local Plugin File

Edit `usb-hotplug.plg` and change the package URL to a local path:

```xml
<!-- Instead of GitHub URL, use local path -->
<FILE Name="/boot/config/plugins/usb-hotplug/usb-hotplug-2025.01.12.txz">
<URL>file:///boot/config/plugins/usb-hotplug/usb-hotplug-2025.01.12.txz</URL>
</FILE>
```

### Step 2: Upload Files

```bash
# Upload to Unraid
scp build/usb-hotplug-2025.01.12.txz root@unraid-ip:/boot/config/plugins/usb-hotplug/
scp usb-hotplug.plg root@unraid-ip:/boot/config/plugins/usb-hotplug/
```

### Step 3: Install via Plugin Manager

1. In Unraid web interface, go to **Plugins**
2. At the bottom, in the "Install Plugin" box, paste:
   ```
   /boot/config/plugins/usb-hotplug/usb-hotplug.plg
   ```
3. Click **Install**

This will run the actual plugin installation process!

## Testing Checklist After Installation

```bash
# 1. Verify files are in place
ls -l /usr/local/sbin/qemu-usb-hotplug*.sh
ls -l /usr/local/sbin/qemu-vm-monitor.sh
ls -l /etc/udev/rules.d/99-qemu-usb-hotplug.rules
ls -l /usr/local/emhttp/plugins/usb-hotplug/USBHotplug.page

# 2. Check monitor is running
ps aux | grep qemu-vm-monitor
# Should show: /bin/bash /usr/local/sbin/qemu-vm-monitor.sh

# 3. Check logs exist and are writable
ls -l /var/log/usb-hotplug.log
tail /var/log/usb-hotplug.log

# 4. Check config file
cat /boot/config/plugins/usb-hotplug/usb-hotplug.cfg

# 5. Test udev rules
udevadm test /sys/bus/usb/devices/usb1 2>&1 | grep hotplug

# 6. Access web UI
# Open browser: http://your-unraid-ip/Settings/USBHotplug
```

## Testing the Functionality

### Test 1: Monitor Detection
```bash
# Watch the logs in one terminal
tail -f /var/log/usb-hotplug.log

# In another terminal, start a VM
virsh start YourVMName

# You should see:
# [DATE TIME] vm-monitor: NEW VM DETECTED: YourVMName
# [DATE TIME] vm-monitor: Scanning for USB devices...
```

### Test 2: Hotplug (Add)
```bash
# Watch logs
tail -f /var/log/usb-hotplug.log

# Plug in a USB device
# You should see within 2 seconds:
# [DATE TIME] qemu-usb-hotplug: ACTION=add VENDOR=xxxx PRODUCT=yyyy
# [DATE TIME] qemu-usb-hotplug: Attaching device...
```

### Test 3: Web UI
1. Go to Settings → USB Hotplug
2. Verify you see:
   - Monitor status (Running)
   - Connected USB devices list
   - Blacklist editor
   - Log viewer
3. Try adding a device to blacklist and saving

### Test 4: Blacklist
```bash
# Add a test device to blacklist
echo "045e:028e  # Xbox Controller" >> /boot/config/plugins/usb-hotplug/usb-hotplug.cfg

# Restart monitor
pkill -f qemu-vm-monitor
nohup /usr/local/sbin/qemu-vm-monitor.sh > /dev/null 2>&1 &

# Start a VM and verify device is NOT attached
tail -f /var/log/usb-hotplug.log
# Should show: "Skipping blacklisted device: 045e:028e"
```

## Troubleshooting

### Web UI Not Showing
```bash
# Check if file exists
ls -l /usr/local/emhttp/plugins/usb-hotplug/USBHotplug.page

# Restart nginx
/etc/rc.d/rc.nginx restart

# Check for PHP errors
tail -f /var/log/nginx/error.log
```

### Monitor Not Starting
```bash
# Check for errors
/usr/local/sbin/qemu-vm-monitor.sh

# Check if virsh works
virsh list --all

# Check permissions
ls -l /usr/local/sbin/qemu-vm-monitor.sh
```

### Devices Not Attaching
```bash
# Check udev rules are loaded
udevadm control --reload-rules

# Test udev trigger manually
udevadm trigger --action=add

# Check logs for errors
tail -50 /var/log/usb-hotplug.log
```

## Uninstall (for testing cleanup)

```bash
# Stop monitor
pkill -f qemu-vm-monitor

# Remove scripts
rm -f /usr/local/sbin/qemu-usb-hotplug*.sh
rm -f /usr/local/sbin/qemu-vm-monitor.sh

# Remove udev rules
rm -f /etc/udev/rules.d/99-qemu-usb-hotplug.rules
udevadm control --reload-rules

# Remove web UI
rm -rf /usr/local/emhttp/plugins/usb-hotplug

# Optional: Remove config (if you want clean slate)
# rm -rf /boot/config/plugins/usb-hotplug
```

## Quick Reinstall for Testing Changes

After making changes to scripts:

```bash
# 1. Rebuild package
cd /path/to/plugin
./build-plugin.sh

# 2. Stop current installation
pkill -f qemu-vm-monitor

# 3. Extract new package
cd /
tar -xf /boot/config/plugins/usb-hotplug/usb-hotplug-2025.01.12.txz

# 4. Restart monitor
nohup /usr/local/sbin/qemu-vm-monitor.sh > /dev/null 2>&1 &

# 5. Check logs
tail -f /var/log/usb-hotplug.log
```

## Pro Tip: Development Workflow

For rapid testing during development:

```bash
# Edit scripts directly on Unraid
nano /usr/local/sbin/qemu-vm-monitor.sh

# Restart to apply changes
pkill -f qemu-vm-monitor
nohup /usr/local/sbin/qemu-vm-monitor.sh > /dev/null 2>&1 &

# Watch logs
tail -f /var/log/usb-hotplug.log

# Once satisfied, copy back to your source
cp /usr/local/sbin/qemu-vm-monitor.sh /tmp/
# Download and update your source files
```

This lets you iterate quickly without rebuilding the package every time!
