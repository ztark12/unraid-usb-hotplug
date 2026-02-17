#!/bin/bash

CONFIG_FILE="/boot/config/plugins/usb-hotplug/usb-hotplug.cfg"

log_msg() {
    logger "vm-monitor: $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /var/log/usb-hotplug.log
}

# Validate config file before reading
validate_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_msg "WARNING: Config file not found, using defaults"
        return 1
    fi

    # Check if file is readable
    if [ ! -r "$CONFIG_FILE" ]; then
        log_msg "ERROR: Config file not readable, check permissions"
        return 1
    fi

    # Test read with timeout to detect corruption
    if ! timeout 2 head -100 "$CONFIG_FILE" > /dev/null 2>&1; then
        log_msg "ERROR: Config file read timeout, possible corruption"
        return 1
    fi

    return 0
}

# Auto-detect and blacklist the boot drive
detect_boot_drive() {
    # Find which device is mounted as /boot
    BOOT_DEVICE=$(mount | grep " /boot " | awk '{print $1}' | sed 's/[0-9]*$//')

    if [ -z "$BOOT_DEVICE" ]; then
        log_msg "WARNING: Could not detect boot device from mount"
        return
    fi

    # Extract just the device name (e.g., sdb from /dev/sdb)
    BOOT_DEV_NAME=$(basename "$BOOT_DEVICE")

    # Find the USB device that corresponds to this block device
    for usb_dev in /sys/bus/usb/devices/*; do
        [ -f "$usb_dev/idVendor" ] || continue

        # Check if this USB device has a block device child
        for block in /sys/block/*; do
            if [ -e "$block/device" ]; then
                BLOCK_USB=$(readlink -f "$block/device" 2>/dev/null)
                USB_PATH=$(readlink -f "$usb_dev" 2>/dev/null)

                # Check if the block device belongs to this USB device
                if [ -n "$BLOCK_USB" ] && [ -n "$USB_PATH" ] && [[ "$BLOCK_USB" == "$USB_PATH"* ]]; then
                    BLOCK_NAME=$(basename "$block")

                    # Check if this is our boot device
                    if [ "$BLOCK_NAME" == "$BOOT_DEV_NAME" ]; then
                        BOOT_VENDOR=$(cat "$usb_dev/idVendor" 2>/dev/null)
                        BOOT_PRODUCT=$(cat "$usb_dev/idProduct" 2>/dev/null)
                        BOOT_ID="${BOOT_VENDOR}:${BOOT_PRODUCT}"

                        # Check if already in blacklist
                        ALREADY_BLACKLISTED=false
                        for blacklisted in "${BLACKLIST[@]}"; do
                            if [ "$BOOT_ID" == "$blacklisted" ]; then
                                ALREADY_BLACKLISTED=true
                                break
                            fi
                        done

                        if [ "$ALREADY_BLACKLISTED" == "false" ]; then
                            log_msg "CRITICAL: Boot drive $BOOT_ID not in blacklist, auto-adding for protection"
                            BLACKLIST+=("$BOOT_ID")
                        fi

                        log_msg "Boot drive detected and protected: $BOOT_ID (device: $BOOT_DEVICE)"
                        return
                    fi
                fi
            fi
        done
    done

    log_msg "WARNING: Could not match boot device $BOOT_DEVICE to USB device"
}

# Load blacklist from config file
load_blacklist() {
    BLACKLIST=()

    # Validate config before attempting to read
    if validate_config; then
        while IFS= read -r line; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

            # Extract device ID (before any comment)
            DEVICE_ID=$(echo "$line" | awk '{print $1}')

            # Validate format (XXXX:XXXX)
            if [[ "$DEVICE_ID" =~ ^[0-9a-fA-F]{4}:[0-9a-fA-F]{4}$ ]]; then
                BLACKLIST+=("$DEVICE_ID")
                log_msg "Blacklisted: $DEVICE_ID"
            fi
        done < "$CONFIG_FILE"
    fi

    # Always include Unraid flash drive as fallback
    if [ ${#BLACKLIST[@]} -eq 0 ]; then
        log_msg "Using fallback blacklist (18a5:0302)"
        BLACKLIST=("18a5:0302")
    fi

    # CRITICAL: Auto-detect and protect the current boot drive
    detect_boot_drive

    log_msg "Loaded ${#BLACKLIST[@]} blacklisted devices"
}

attach_usb_devices() {
    VM_NAME="$1"
    log_msg "Scanning for USB devices to attach to $VM_NAME"
    
    # Reload blacklist each time
    load_blacklist
    
    ATTACHED_COUNT=0
    SKIPPED_COUNT=0
    
    for usb_device in /sys/bus/usb/devices/*; do
        [ -f "$usb_device/idVendor" ] || continue
        
        VENDOR=$(cat "$usb_device/idVendor" 2>/dev/null)
        PRODUCT=$(cat "$usb_device/idProduct" 2>/dev/null)
        BUSNUM=$(cat "$usb_device/busnum" 2>/dev/null)
        DEVNUM=$(cat "$usb_device/devnum" 2>/dev/null)
        
        [ -z "$VENDOR" ] || [ -z "$PRODUCT" ] || [ -z "$BUSNUM" ] || [ -z "$DEVNUM" ] && continue
        
        DEVICE_ID="${VENDOR}:${PRODUCT}"
        DEVICE_CLASS=$(cat "$usb_device/bDeviceClass" 2>/dev/null)
        
        # Skip hubs (class 09)
        if [ "$DEVICE_CLASS" == "09" ]; then
            log_msg "SKIP hub: $DEVICE_ID (bus:$BUSNUM dev:$DEVNUM)"
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
            continue
        fi
        
        # Skip blacklist
        SKIP=false
        for blacklisted in "${BLACKLIST[@]}"; do
            if [ "$DEVICE_ID" == "$blacklisted" ]; then
                SKIP=true
                log_msg "SKIP blacklisted: $DEVICE_ID (bus:$BUSNUM dev:$DEVNUM)"
                break
            fi
        done

        if [ "$SKIP" == "true" ]; then
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
            continue
        fi
        
        # Check if already attached (with timeout protection)
        ALREADY_ATTACHED=false
        if timeout 2 virsh dumpxml "$VM_NAME" 2>/dev/null | grep -q "bus='$BUSNUM' device='$DEVNUM'"; then
            ALREADY_ATTACHED=true
        fi
        
        if [ "$ALREADY_ATTACHED" == "true" ]; then
            log_msg "SKIP already attached: ${DEVICE_ID} (bus:$BUSNUM dev:$DEVNUM)"
            continue
        fi

        # SAFETY: independently verify this device is not the current boot drive
        # This is a defense-in-depth check that does NOT depend on the blacklist
        BOOT_DEV=$(mount | grep " /boot " | awk '{print $1}')
        if [ -n "$BOOT_DEV" ]; then
            IS_BOOT=false
            for usb_check in /sys/bus/usb/devices/*; do
                [ -f "$usb_check/idVendor" ] || continue
                CHECK_BUS=$(cat "$usb_check/busnum" 2>/dev/null)
                CHECK_DEV=$(cat "$usb_check/devnum" 2>/dev/null)
                if [ "$CHECK_BUS" = "$BUSNUM" ] && [ "$CHECK_DEV" = "$DEVNUM" ]; then
                    BOOT_BLOCK=$(ls /sys/block/ 2>/dev/null | while read blk; do
                        BLK_USB=$(readlink -f "/sys/block/$blk/device" 2>/dev/null)
                        USB_P=$(readlink -f "$usb_check" 2>/dev/null)
                        [[ -n "$BLK_USB" && -n "$USB_P" && "$BLK_USB" == "$USB_P"* ]] && echo "$blk"
                    done)
                    if [ -n "$BOOT_BLOCK" ] && echo "$BOOT_DEV" | grep -q "$BOOT_BLOCK"; then
                        log_msg "CRITICAL SAFETY BLOCK: $DEVICE_ID (bus:$BUSNUM dev:$DEVNUM) is the boot drive! Refusing to attach."
                        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
                        IS_BOOT=true
                    fi
                    break
                fi
            done
            [ "$IS_BOOT" = "true" ] && continue
        fi

        XML_FILE="/tmp/usb-startup-${BUSNUM}-${DEVNUM}.xml"
        
        cat > "$XML_FILE" << XMLEOF
<hostdev mode='subsystem' type='usb' managed='yes'>
  <source>
    <address bus='$BUSNUM' device='$DEVNUM'/>
  </source>
</hostdev>
XMLEOF
        
        ATTACH_OUTPUT=$(timeout 5 virsh attach-device "$VM_NAME" "$XML_FILE" --live 2>&1)
        ATTACH_RESULT=$?
        
        if [ $ATTACH_RESULT -eq 0 ]; then
            log_msg "SUCCESS: Attached ${DEVICE_ID} (bus:$BUSNUM dev:$DEVNUM)"
            ATTACHED_COUNT=$((ATTACHED_COUNT + 1))
        elif echo "$ATTACH_OUTPUT" | grep -q "already"; then
            log_msg "Already attached: ${DEVICE_ID}"
        else
            log_msg "Failed to attach ${DEVICE_ID}: $ATTACH_OUTPUT"
        fi
        
        rm -f "$XML_FILE"
        
        sleep 0.2
    done
    
    log_msg "Summary: Attached $ATTACHED_COUNT devices, skipped $SKIPPED_COUNT"
}

# Single-instance lock: prevent multiple monitor instances
PIDFILE="/var/run/usb-hotplug-monitor.pid"
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        log_msg "Another instance already running (PID: $OLD_PID), exiting"
        exit 0
    fi
fi
echo $$ > "$PIDFILE"
trap "rm -f '$PIDFILE'" EXIT

log_msg "VM monitor started (PID: $$)"

# Pre-flight check: Verify boot drive is accessible
if ! timeout 5 ls /boot/config/plugins/usb-hotplug/ > /dev/null 2>&1; then
    log_msg "FATAL: Cannot access boot drive (/boot), monitor exiting to prevent system corruption"
    exit 1
fi

log_msg "Boot drive health check: OK"

# Load initial blacklist
load_blacklist

# Wait for libvirt to become available before entering the main loop.
# On boot the monitor starts before libvirtd is ready, so we poll silently
# rather than burning through MAX_ERRORS and exiting.
log_msg "Waiting for libvirt to become ready..."
LIBVIRT_WAIT=0
LIBVIRT_TIMEOUT=300
while ! timeout 3 virsh list --name > /dev/null 2>&1; do
    sleep 5
    LIBVIRT_WAIT=$((LIBVIRT_WAIT + 5))
    if [ $LIBVIRT_WAIT -ge $LIBVIRT_TIMEOUT ]; then
        log_msg "FATAL: libvirt not available after ${LIBVIRT_TIMEOUT}s, monitor exiting"
        exit 1
    fi
done
log_msg "libvirt is ready (waited ${LIBVIRT_WAIT}s)"

PREVIOUS_VMS=""
ERROR_COUNT=0
MAX_ERRORS=10

while true; do
    # Get running VMs with timeout and error handling
    CURRENT_VMS=$(timeout 3 virsh list --name --state-running 2>/dev/null)
    VIRSH_RESULT=$?
    
    if [ $VIRSH_RESULT -ne 0 ]; then
        ERROR_COUNT=$((ERROR_COUNT + 1))
        log_msg "ERROR: virsh command failed (error count: $ERROR_COUNT)"
        
        if [ $ERROR_COUNT -ge $MAX_ERRORS ]; then
            log_msg "FATAL: Too many errors, monitor exiting"
            exit 1
        fi
        
        sleep 5
        continue
    fi
    
    # Reset error count on success
    ERROR_COUNT=0
    
    # Check for newly started VMs
    if [ -n "$CURRENT_VMS" ]; then
        while IFS= read -r vm; do
            [ -z "$vm" ] && continue
            
            if ! echo "$PREVIOUS_VMS" | grep -Fq "$vm"; then
                log_msg "NEW VM DETECTED: $vm"
                sleep 10
                
                # Run attach in a way that won't crash the monitor
                (attach_usb_devices "$vm") || log_msg "ERROR: attach_usb_devices failed for $vm"
            fi
        done <<< "$CURRENT_VMS"
    fi
    
    PREVIOUS_VMS="$CURRENT_VMS"
    
    sleep 2
done
