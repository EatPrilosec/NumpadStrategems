#!/usr/bin/env bash
# One-time setup to allow NumpadStrategems to access input devices without sudo.
# Run this once from a real terminal:  sudo bash setup_input.sh

set -e

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root:"
    echo "  sudo bash $0"
    exit 1
fi

USER_NAME="${SUDO_USER:-$USER}"

echo "=== NumpadStrategems Input Permissions Setup ==="
echo

# 1. Create input group if it doesn't exist
if ! getent group input >/dev/null 2>&1; then
    echo "Creating 'input' group..."
    groupadd input
else
    echo "'input' group already exists."
fi

# 2. Add user to input group
if id -nG "$USER_NAME" | grep -qw input; then
    echo "User '$USER_NAME' is already in 'input' group."
else
    echo "Adding '$USER_NAME' to 'input' group..."
    usermod -aG input "$USER_NAME"
fi

# 3. Create udev rule so input devices are owned by the input group
RULE_FILE="/etc/udev/rules.d/99-input.rules"
UINPUT_RULE='KERNEL=="uinput", GROUP="input", MODE="0660"'
INPUT_RULE='KERNEL=="event*", SUBSYSTEM=="input", GROUP="input", MODE="0660"'

echo "Writing udev rules to $RULE_FILE..."
mkdir -p /etc/udev/rules.d
cat > "$RULE_FILE" << 'EOF'
# Allow members of 'input' group to access input devices and uinput
KERNEL=="event*", SUBSYSTEM=="input", GROUP="input", MODE="0660"
KERNEL=="uinput", GROUP="input", MODE="0660"
EOF

# 4. Ensure /dev/uinput exists and is accessible (needed to create virtual keyboard)
if [ ! -e /dev/uinput ]; then
    echo "Loading uinput kernel module..."
    modprobe uinput
fi

# Make uinput module load on boot
if [ ! -f /etc/modules-load.d/uinput.conf ]; then
    echo "Enabling uinput module on boot..."
    mkdir -p /etc/modules-load.d
    echo "uinput" > /etc/modules-load.d/uinput.conf
fi

# 5. Reload udev rules and re-trigger
echo "Reloading udev rules..."
udevadm control --reload-rules
udevadm trigger --subsystem-match=input

echo
echo "=== Done! ==="
echo
echo "You MUST log out and log back in for group changes to take effect."
echo "After that, run NumpadStrategems.py without sudo."
echo
echo "To verify, run:  groups $USER_NAME"
echo "You should see 'input' in the list."
