<?php
// AJAX handler for USB Hotplug plugin
// This file is separate from the .page file to avoid Unraid's HTML wrapping

header('Content-Type: application/json');

// Check for POST request with update_blacklist action
if ($_SERVER['REQUEST_METHOD'] !== 'POST' || !isset($_POST['action']) || $_POST['action'] !== 'update_blacklist') {
    echo json_encode(['success' => false, 'error' => 'Invalid request']);
    exit;
}

// Plugin configuration
$plugin = "usb-hotplug";
$cfg_file = "/boot/config/plugins/$plugin/usb-hotplug.cfg";

// Get and validate device list
$devices_json = $_POST['devices'] ?? '[]';
$checked_devices = json_decode($devices_json, true);

if (!is_array($checked_devices)) {
    echo json_encode(['success' => false, 'error' => 'Invalid device data']);
    exit;
}

// Generate config file content
$content = "";
foreach ($checked_devices as $device_id) {
    // Validate format: vendor:product (4 hex digits : 4 hex digits)
    if (preg_match('/^[0-9a-fA-F]{4}:[0-9a-fA-F]{4}$/', $device_id)) {
        $content .= "$device_id\n";
    }
}

// Write to config file
$result = file_put_contents($cfg_file, $content);

if ($result !== false) {
    // Restart monitor to apply changes
    shell_exec("pkill -f qemu-vm-monitor.sh 2>&1");
    sleep(1);
    shell_exec("nohup /usr/local/sbin/qemu-vm-monitor.sh > /dev/null 2>&1 &");

    echo json_encode(['success' => true]);
} else {
    echo json_encode(['success' => false, 'error' => 'Failed to write config file']);
}
exit;
