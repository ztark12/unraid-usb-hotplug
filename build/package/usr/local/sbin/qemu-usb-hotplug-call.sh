#!/bin/bash
sleep 0.$((RANDOM % 5))
/usr/local/sbin/qemu-usb-hotplug.sh "$@" &
