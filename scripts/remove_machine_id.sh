#!/bin/bash

echo "Removing machine id"

if [[ -e /etc/machine-id ]]; then sudo rm -f /etc/machine-id && sudo touch /etc/machine-id; fi

if [[ -e /var/lib/dbus/machine-id && ! -h /var/lib/dbus/machine-id ]]; then sudo rm -f /var/lib/dbus/machine-id; fi
