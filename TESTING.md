# USB Hotplug Plugin - Testing Checklist

Complete this checklist before releasing the plugin publicly.

## Pre-Installation Testing

### Environment Check
- [ ] Fresh Unraid 6.9+ installation available for testing
- [ ] At least one VM configured with qemu-xhci USB controller
- [ ] Multiple USB devices available for testing
- [ ] SSH access to Unraid server configured

### File Integrity
- [ ] All scripts have proper shebang (`#!/bin/bash`)
- [ ] All scripts are executable (chmod +x)
- [ ] No syntax errors in bash scripts (`bash -n script.sh`)
- [ ] No syntax errors in XML file
- [ ] No syntax errors in PHP file

## Installation Testing

### Plugin Installation
- [ ] Plugin installs without errors
- [ ] All files copied to correct locations
- [ ] Monitor starts automatically (check with `ps aux | grep qemu-vm-monitor`)
- [ ] Udev rules loaded (`udevadm control --reload-rules`)
- [ ] Log file created at `/var/log/usb-hotplug.log`
- [ ] Config file created at `/boot/config/plugins/usb-hotplug/usb-hotplug.cfg`
- [ ] Web UI accessible at Settings → USB Hotplug

### Web UI Testing
- [ ] Settings page loads without errors
- [ ] Monitor status displays correctly
- [ ] Currently connected devices list populates
- [ ] Blacklist editor displays default content
- [ ] Log viewer shows entries
- [ ] All buttons are functional:
  - [ ] Restart Monitor
  - [ ] Stop Monitor
  - [ ] Clear Log
  - [ ] Refresh
  - [ ] Save Blacklist

## Functional Testing

### VM Startup Behavior
- [ ] Start VM with no USB devices connected
  - [ ] Monitor detects VM start
  - [ ] Log shows "NEW VM DETECTED"
  
- [ ] Start VM with USB devices connected
  - [ ] Non-blacklisted devices attach automatically
  - [ ] Blacklisted devices are skipped
  - [ ] Correct count shown in log (Attached X devices, skipped Y)
  - [ ] Devices work in guest OS

### Hotplug Testing - Device Addition
- [ ] Plug in USB keyboard with VM running
  - [ ] Device attaches within 2 seconds
  - [ ] Log shows successful attachment
  - [ ] Device works immediately in guest OS
  
- [ ] Plug in USB mouse with VM running
  - [ ] Device attaches within 2 seconds
  - [ ] Mouse cursor appears in guest OS
  
- [ ] Plug in USB game controller
  - [ ] Device attaches successfully
  - [ ] Controller recognized in guest OS

### Hotplug Testing - Device Removal
- [ ] Unplug USB keyboard while VM running
  - [ ] Device removed from VM immediately
  - [ ] No error messages in log
  - [ ] Stale references cleaned up
  
- [ ] Unplug USB mouse while VM running
  - [ ] Device removed cleanly
  - [ ] No VM instability

### State Change Testing (8BitDo Controllers)
- [ ] Connect 8BitDo controller in IDLE mode
  - [ ] Controller attaches
  
- [ ] Press HOME button to switch to Active mode
  - [ ] Device re-attaches automatically
  - [ ] Works in guest OS
  
- [ ] Let controller return to IDLE
  - [ ] Handles state change gracefully

### Multiple Identical Devices
- [ ] Connect two identical USB devices (same vendor/product ID)
  - [ ] Both devices attach successfully
  - [ ] Both work independently in guest OS
  - [ ] No conflicts in log

### Blacklist Testing
- [ ] Add device to blacklist via web UI
  - [ ] Save blacklist
  - [ ] Monitor restarts
  
- [ ] Start VM
  - [ ] Blacklisted device not attached
  - [ ] Log shows device was skipped
  
- [ ] Remove device from blacklist
  - [ ] Save changes
  - [ ] Start new VM
  - [ ] Device now attaches

### Edge Cases
- [ ] Start multiple VMs simultaneously
  - [ ] Devices attach to first running VM
  - [ ] No race conditions or crashes
  
- [ ] Rapid plug/unplug (10 times in 10 seconds)
  - [ ] System handles gracefully
  - [ ] No duplicate attachments
  - [ ] No crashes
  
- [ ] Disconnect device while VM is paused
  - [ ] System handles gracefully
  - [ ] No stale references
  
- [ ] Stop VM with devices attached
  - [ ] Monitor continues running
  - [ ] Ready for next VM start

## Persistence Testing

### Reboot Test
- [ ] Configure blacklist with custom entries
- [ ] Reboot Unraid server
- [ ] After reboot:
  - [ ] Monitor starts automatically
  - [ ] Scripts are in place
  - [ ] Udev rules loaded
  - [ ] Config file preserved
  - [ ] Web UI still accessible
  - [ ] Blacklist settings preserved
  - [ ] Start VM and verify devices attach

### Update Test
- [ ] Simulate Unraid update (reboot)
- [ ] Verify plugin still works after update
- [ ] Check `/boot/config/go` contains startup commands

## Error Handling Testing

### Monitor Crash Recovery
- [ ] Kill monitor process: `pkill -f qemu-vm-monitor`
- [ ] Restart via web UI or manually
- [ ] Verify monitor recovers and functions normally

### Invalid Device IDs
- [ ] Add malformed entry to blacklist: `ZZZZ:YYYY`
- [ ] Save and check logs
- [ ] Verify invalid entries are ignored

### Virsh Errors
- [ ] Temporarily make virsh unavailable
- [ ] Verify monitor logs errors but doesn't crash
- [ ] Restore virsh
- [ ] Verify monitor recovers

### Full Disk
- [ ] Fill log file to large size
- [ ] Verify system still functions
- [ ] Clear log and verify continues

## Performance Testing

### Resource Usage
- [ ] Check CPU usage: `top` - should be minimal
- [ ] Check memory usage: `free -h` - should be minimal
- [ ] Monitor for memory leaks over 24 hours

### Latency
- [ ] Measure time from plug to attachment
  - [ ] Should be < 2 seconds
- [ ] Measure VM startup delay
  - [ ] Should add < 15 seconds to startup

## Uninstall Testing

### Clean Removal
- [ ] Uninstall plugin via web UI
- [ ] Verify all components removed:
  - [ ] Scripts removed from /usr/local/sbin/
  - [ ] Udev rules removed
  - [ ] Web UI files removed
  - [ ] Monitor process stopped
- [ ] Verify config file preserved (for backup)
- [ ] Reinstall plugin
- [ ] Verify previous settings restored

## Documentation Testing

### README Accuracy
- [ ] Follow installation instructions verbatim
- [ ] Test all command examples
- [ ] Verify all URLs work
- [ ] Check troubleshooting steps solve actual issues

### Web UI Help Text
- [ ] Read all help text in web UI
- [ ] Verify instructions are clear and accurate

## Browser Compatibility (Web UI)

- [ ] Test in Chrome/Chromium
- [ ] Test in Firefox
- [ ] Test in Safari
- [ ] Test in Edge
- [ ] Test on mobile browser

## Security Testing

### Input Validation
- [ ] Try to inject shell commands in blacklist field
- [ ] Verify input is sanitized
- [ ] Try to break out of web UI forms

### File Permissions
- [ ] Check all scripts are owned by root
- [ ] Verify no world-writable files created
- [ ] Check log file permissions are appropriate

## Compatibility Testing

### Different Unraid Versions
- [ ] Test on Unraid 6.9.x
- [ ] Test on Unraid 6.10.x
- [ ] Test on Unraid 6.11.x
- [ ] Test on Unraid 6.12.x (latest)

### Different USB Controllers
- [ ] Test with qemu-xhci (recommended)
- [ ] Test with legacy USB controllers
- [ ] Test with USB 2.0 only VMs
- [ ] Test with USB 3.0 VMs

### Guest Operating Systems
- [ ] Test with Windows 10 VM
- [ ] Test with Windows 11 VM
- [ ] Test with Linux VM (Ubuntu)
- [ ] Test with macOS VM (if applicable)

## Final Checks Before Release

- [ ] All tests passed
- [ ] No critical bugs found
- [ ] Documentation complete and accurate
- [ ] Version number correct in all files
- [ ] GitHub repository prepared
- [ ] Release notes written
- [ ] Forum thread drafted
- [ ] Support plan in place

## Post-Release Monitoring

After release, monitor for 48 hours:
- [ ] Check forum thread for issues
- [ ] Monitor GitHub issues
- [ ] Review installation analytics (if available)
- [ ] Collect user feedback
- [ ] Update FAQ based on common questions

## Notes

Use this section to record any issues found during testing:

---

**Test Date:** _________________

**Tested By:** _________________

**Unraid Version:** _________________

**Issues Found:**

1. 

2. 

3. 

**Resolution Status:**

- [ ] All issues resolved
- [ ] Known issues documented
- [ ] Ready for release
