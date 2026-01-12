#!/bin/bash

CONFIG_FILE="/boot/config/plugins/usb-hotplug/usb-hotplug.cfg"

log_msg() {
    logger "vm-monitor: $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /var/log/usb-hotplug.log
}

# Load blacklist from config file
load_blacklist() {
    BLACKLIST=()
    
    if [ -f "$CONFIG_FILE" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

            # Extract device ID (before any comment)
            DEVICE_ID=$(echo "$line" | awk '{print $1}')

            # Validate format (XXXX:XXXX)
            if [[ "$DEVICE_ID" =~ ^[0-9a-fA-F]{4}:[0-9a-fA-F]{4}$ ]]; then
                BLACKLIST+=("$DEVICE_ID")
            fi
        done < "$CONFIG_FILE"
    fi
    
    # Always include Unraid flash drive as fallback
    if [ ${#BLACKLIST[@]} -eq 0 ]; then
        BLACKLIST=("18a5:0302")
    fi
    
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
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
            continue
        fi
        
        # Skip blacklist
        SKIP=false
        for blacklisted in "${BLACKLIST[@]}"; do
            if [ "$DEVICE_ID" == "$blacklisted" ]; then
                SKIP=true
                log_msg "Skipping blacklisted device: $DEVICE_ID"
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
            log_msg "Already attached: ${DEVICE_ID} (bus:$BUSNUM dev:$DEVNUM)"
            continue
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

log_msg "VM monitor started (PID: $$)"

# Load initial blacklist
load_blacklist

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
