<?php
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST' || !isset($_POST['action']) || $_POST['action'] !== 'update_blacklist') {
    echo json_encode(['success' => false, 'error' => 'Invalid request']);
    exit;
}

$plugin = "usb-hotplug";
$cfg_file = "/boot/config/plugins/$plugin/usb-hotplug.cfg";

function detect_boot_device_id() {
    $mount_output = shell_exec("mount | grep ' /boot '") ?? '';
    if (!$mount_output) return null;
    preg_match('/^(\/dev\/[a-z]+)/', $mount_output, $matches);
    if (!$matches) return null;
    $boot_device = basename(preg_replace('/[0-9]+$/', '', $matches[1]));
    foreach (glob('/sys/bus/usb/devices/*') as $usb_dev) {
        if (!file_exists("$usb_dev/idVendor")) continue;
        foreach (glob('/sys/block/*') as $block) {
            if (!file_exists("$block/device")) continue;
            $block_usb = realpath("$block/device");
            $usb_path = realpath($usb_dev);
            if ($block_usb && $usb_path && strpos($block_usb, $usb_path) === 0) {
                if (basename($block) === $boot_device) {
                    $vendor = trim(file_get_contents("$usb_dev/idVendor"));
                    $product = trim(file_get_contents("$usb_dev/idProduct"));
                    return "$vendor:$product";
                }
            }
        }
    }
    return null;
}

$devices_json = $_POST['devices'] ?? '[]';
$checked_devices = json_decode($devices_json, true);

if (!is_array($checked_devices)) {
    echo json_encode(['success' => false, 'error' => 'Invalid device data']);
    exit;
}

$boot_device_id = detect_boot_device_id();

$content = "";
$seen = [];
foreach ($checked_devices as $device_id) {
    if (!preg_match('/^[0-9a-fA-F]{4}:[0-9a-fA-F]{4}(@[\d.\-]+)?$/', $device_id)) continue;

    // Boot drive always saved as global entry (strip @port) to ensure
    // protection regardless of future port changes.
    $base_id = strpos($device_id, '@') !== false ? explode('@', $device_id, 2)[0] : $device_id;
    if ($boot_device_id !== null && $base_id === $boot_device_id) {
        $device_id = $base_id;
    }

    if (isset($seen[$device_id])) continue;
    $seen[$device_id] = true;
    $content .= "$device_id\n";
}

$result = file_put_contents($cfg_file, $content);

if ($result !== false) {
    shell_exec("pkill -f qemu-vm-monitor.sh 2>/dev/null");
    sleep(2);
    shell_exec("pkill -9 -f qemu-vm-monitor.sh 2>/dev/null");
    shell_exec("nohup /usr/local/sbin/qemu-vm-monitor.sh > /dev/null 2>&1 &");
    echo json_encode(['success' => true]);
} else {
    echo json_encode(['success' => false, 'error' => 'Failed to write config file']);
}
exit;
