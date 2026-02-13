#!/bin/bash

echo "========================================="
echo "USB Hotplug Plugin - Build Script"
echo "========================================="
echo ""

VERSION="2025.02.11b"
PLUGIN_NAME="usb-hotplug"
BUILD_DIR="build"
PACKAGE_NAME="${PLUGIN_NAME}-${VERSION}"

# Clean up old build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/package"

echo "Creating directory structure..."

# Create directory structure
mkdir -p "$BUILD_DIR/package/usr/local/sbin"
mkdir -p "$BUILD_DIR/package/etc/udev/rules.d"
mkdir -p "$BUILD_DIR/package/usr/local/emhttp/plugins/$PLUGIN_NAME"
mkdir -p "$BUILD_DIR/package/boot/config/plugins/$PLUGIN_NAME"

echo "Copying scripts..."

# Copy main scripts (using the ones from your original install script)
cat > "$BUILD_DIR/package/usr/local/sbin/qemu-usb-hotplug.sh" << 'SCRIPT1'
#!/bin/bash

ACTION=$1
VENDOR=$2
PRODUCT=$3

log_msg() {
    logger "qemu-usb-hotplug: $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /var/log/usb-hotplug.log
}

log_msg "ACTION=$ACTION VENDOR=$VENDOR PRODUCT=$PRODUCT"

RUNNING_VM=$(timeout 3 virsh list --state-running --name 2>/dev/null | head -n 1)

if [ -z "$RUNNING_VM" ]; then
    log_msg "No running VM found"
    exit 0
fi

if [ "$ACTION" == "remove" ]; then
    log_msg "Device ${VENDOR}:${PRODUCT} unplugged"
    
    # Find and remove stale USB device entries
    virsh dumpxml "$RUNNING_VM" | grep -A10 "hostdev mode='subsystem' type='usb'" | while IFS= read -r line; do
        if echo "$line" | grep -q "<address bus="; then
            BUS=$(echo "$line" | sed -n "s/.*bus='\([0-9]*\)'.*/\1/p")
            DEV=$(echo "$line" | sed -n "s/.*device='\([0-9]*\)'.*/\1/p")
            
            if [ -n "$BUS" ] && [ -n "$DEV" ]; then
                DEVICE_INFO=$(lsusb -s ${BUS}:${DEV} 2>/dev/null)
                
                if [ -z "$DEVICE_INFO" ]; then
                    log_msg "Removing stale entry bus:$BUS dev:$DEV"
                    
                    XML_FILE="/tmp/usb-detach-${BUS}-${DEV}-$$.xml"
                    cat > "$XML_FILE" << XMLEOF
<hostdev mode='subsystem' type='usb'>
  <source>
    <address bus='$BUS' device='$DEV'/>
  </source>
</hostdev>
XMLEOF
                    
                    virsh detach-device "$RUNNING_VM" "$XML_FILE" --live 2>&1 | logger
                    rm -f "$XML_FILE"
                fi
            fi
        fi
    done
    
    exit 0
fi

if [ "$ACTION" == "add" ]; then
    sleep 0.5
    
    # Find the new device
    FOUND_DEVICE=""
    MAX_ATTEMPTS=10
    ATTEMPT=0
    
    while [ $ATTEMPT -lt $MAX_ATTEMPTS ] && [ -z "$FOUND_DEVICE" ]; do
        for dev in /sys/bus/usb/devices/*; do
            [ -f "$dev/idVendor" ] || continue
            
            DEV_VENDOR=$(cat "$dev/idVendor" 2>/dev/null)
            DEV_PRODUCT=$(cat "$dev/idProduct" 2>/dev/null)
            
            if [ "$DEV_VENDOR" == "$VENDOR" ] && [ "$DEV_PRODUCT" == "$PRODUCT" ]; then
                BUSNUM=$(cat "$dev/busnum" 2>/dev/null)
                DEVNUM=$(cat "$dev/devnum" 2>/dev/null)
                
                if [ -n "$BUSNUM" ] && [ -n "$DEVNUM" ]; then
                    # Make sure this device isn't already in the VM
                    if ! virsh dumpxml "$RUNNING_VM" 2>/dev/null | grep -q "bus='$BUSNUM' device='$DEVNUM'"; then
                        FOUND_DEVICE="$dev"
                        break 2
                    fi
                fi
            fi
        done
        
        ATTEMPT=$((ATTEMPT + 1))
        sleep 0.2
    done

    if [ -z "$FOUND_DEVICE" ]; then
        log_msg "Could not find new device ${VENDOR}:${PRODUCT}"
        exit 1
    fi

    BUSNUM=$(cat "$FOUND_DEVICE/busnum" 2>/dev/null)
    DEVNUM=$(cat "$FOUND_DEVICE/devnum" 2>/dev/null)

    log_msg "Attaching ${VENDOR}:${PRODUCT} at bus:$BUSNUM dev:$DEVNUM"

    XML_FILE="/tmp/usb-add-${BUSNUM}-${DEVNUM}-$$.xml"

    cat > "$XML_FILE" << XMLEOF
<hostdev mode='subsystem' type='usb' managed='yes'>
  <source>
    <address bus='$BUSNUM' device='$DEVNUM'/>
  </source>
</hostdev>
XMLEOF
    
    ATTACH_OUTPUT=$(timeout 5 virsh attach-device "$RUNNING_VM" "$XML_FILE" --live 2>&1)
    ATTACH_RESULT=$?
    
    if [ $ATTACH_RESULT -eq 0 ]; then
        log_msg "SUCCESS: Attached ${VENDOR}:${PRODUCT} (bus:$BUSNUM dev:$DEVNUM)"
    else
        log_msg "FAILED: ${VENDOR}:${PRODUCT} - $ATTACH_OUTPUT"
    fi
    
    rm -f "$XML_FILE"
fi
SCRIPT1

cat > "$BUILD_DIR/package/usr/local/sbin/qemu-usb-hotplug-call.sh" << 'SCRIPT2'
#!/bin/bash
sleep 0.$((RANDOM % 5))
/usr/local/sbin/qemu-usb-hotplug.sh "$@" &
SCRIPT2

# Copy the updated VM monitor (reads from config file)
cp qemu-vm-monitor.sh "$BUILD_DIR/package/usr/local/sbin/qemu-vm-monitor.sh"

echo "Creating udev rules..."

# Create udev rules
cat > "$BUILD_DIR/package/etc/udev/rules.d/99-qemu-usb-hotplug.rules" << 'UDEV'
# USB Hotplug for VMs
# Excludes hubs and devices in blacklist (configured via web UI)
SUBSYSTEM=="usb", ACTION=="add", ENV{DEVTYPE}=="usb_device", ATTR{bDeviceClass}!="09", RUN+="/usr/local/sbin/qemu-usb-hotplug-call.sh add $attr{idVendor} $attr{idProduct}"

SUBSYSTEM=="usb", ACTION=="remove", ENV{DEVTYPE}=="usb_device", ATTR{bDeviceClass}!="09", RUN+="/usr/local/sbin/qemu-usb-hotplug-call.sh remove $attr{idVendor} $attr{idProduct}"
UDEV

echo "Copying web UI..."

# Copy web UI page and AJAX handler
cp USBHotplug.page "$BUILD_DIR/package/usr/local/emhttp/plugins/$PLUGIN_NAME/"
cp ajax_handler.php "$BUILD_DIR/package/usr/local/emhttp/plugins/$PLUGIN_NAME/"

# Create default config file (without example line that causes confusion)
cat > "$BUILD_DIR/package/boot/config/plugins/$PLUGIN_NAME/usb-hotplug.cfg" << 'CONFIG'
# USB Hotplug Blacklist Configuration
# Format: VENDOR_ID:PRODUCT_ID  # Description

18a5:0302  # Unraid flash drive
CONFIG

echo "Creating package..."

# Create the tarball
cd "$BUILD_DIR/package"
tar -cJf "../${PACKAGE_NAME}.txz" *
cd ../..

echo ""
echo "========================================="
echo "Package created successfully!"
echo "========================================="
echo ""
echo "Package: $BUILD_DIR/${PACKAGE_NAME}.txz"
echo "Plugin file: usb-hotplug.plg"
echo ""
echo "Next steps:"
echo "1. Create a GitHub repository"
echo "2. Upload ${PACKAGE_NAME}.txz to GitHub releases"
echo "3. Update usb-hotplug.plg with your GitHub username"
echo "4. Commit both files to the repository"
echo "5. Test installation via: https://raw.githubusercontent.com/USERNAME/REPO/master/usb-hotplug.plg"
echo ""
