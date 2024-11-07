#!/bin/bash

# Check if we received a drive argument
if [ -z "$1" ]; then
  echo "Usage: $0 /dev/sdx"
  exit 1
fi

TARGET_DRIVE=$1

# Confirm the drive to be used
echo "You are about to install Debian on ${TARGET_DRIVE}. Proceed? (y/n)"
read confirmation
if [ "$confirmation" != "y" ]; then
  echo "Operation cancelled."
  exit 1
fi

# Wipe the drive (CAUTION: This will erase all data on the drive)
echo "Wiping the drive ${TARGET_DRIVE}..."
sgdisk --zap-all "$TARGET_DRIVE"

# Create new partition table and a single ext4 partition
echo "Creating partition table on ${TARGET_DRIVE}..."
parted -s "$TARGET_DRIVE" mklabel gpt
parted -s "$TARGET_DRIVE" mkpart primary ext4 0% 100%

# Format the partition as ext4
echo "Formatting the partition as ext4..."
mkfs.ext4 "${TARGET_DRIVE}1"

# Mount the partition
echo "Mounting the new partition..."
mount "${TARGET_DRIVE}1" /mnt

# Ensure necessary directories for chroot exist
echo "Creating necessary directories for chroot..."
mkdir -p /mnt/dev /mnt/proc /mnt/sys /mnt/run

# Install basic Debian system using debootstrap
echo "Installing a basic Debian system..."
debootstrap --arch amd64 stable /mnt http://deb.debian.org/debian

# Mount necessary filesystems for chroot
echo "Mounting necessary filesystems..."
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys
mount --bind /run /mnt/run

# Chroot into the new system
echo "Chrooting into the new system..."
chroot /mnt /bin/bash <<EOF

# Set up the time zone
echo "Setting time zone..."
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Install basic utilities
echo "Installing basic utilities..."
apt update
apt install -y sudo nano wget curl dialog

# Install GNOME and lightweight packages
echo "Installing GNOME desktop and necessary packages..."
apt install -y gnome-core gdm3 xorg lightdm gnome-terminal \
    nautilus network-manager gnome-control-center \
    gnome-tweaks

# Install additional tools and utilities for system management
echo "Installing essential system tools..."
apt install -y bash-completion vim htop unzip \
    build-essential linux-headers-$(uname -r) \
    software-properties-common

# Enable GDM display manager to start on boot
echo "Enabling GDM display manager..."
systemctl enable gdm3

# Enable networking
echo "Enabling NetworkManager..."
systemctl enable NetworkManager

# Set up sudo for the root user
echo "Setting up sudo for the root user..."
echo "root ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/root

# Set a root password (for initial login)
echo "Setting root password..."
echo "root:root" | chpasswd

# Clean up APT cache to reduce image size
echo "Cleaning up APT cache..."
apt clean

EOF

# Unmount the filesystems
echo "Unmounting the system..."
umount -R /mnt

# Installation complete
echo "Debian installation with GNOME desktop is complete on ${TARGET_DRIVE}."
echo "You can now reboot and use the new system."

