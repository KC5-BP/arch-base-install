#!/bin/sh

# VARIABLES
LANG_EN=en_US.UTF-8
LANG_EN=fr_CH.UTF-8
KEYMAP_LAYOUT=fr_CH-latin1
HOSTNAME=mmmmmh

echo "Setting up TIME ZONE"
ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime

#echo "Setting up DATE & CLOCK to hardware"
#hwclk --systohc

echo "Setting up LOCALIZATION"
echo "For $LANG_EN"
sed -i '177s/.//' /etc/locale.gen 
echo "For $LANG_FR"
sed -i '246s/.//' /etc/locale.gen
echo "Putting language in locale.conf"
echo "LANG=$LANG_EN" >> /etc/locale.conf
echo "Putting keyboard layout in vconsole.conf"
echo "KEYMAP=$KEYBOARD_LAYOUT" >> /etc/vconsole.conf

echo "Setting up HOSTNAME & NETWORK CFG"
echo "$HOSTNAME" >> /etc/hostname
echo "127.0.0.1		localhost" >> /etc/hosts
echo "::1		localhost" >> /etc/hosts
echo "127.0.1.1		$HOSTNAME.localdomain	$HOSTNAME" >> /etc/hosts

echo "Setting up ROOT PASSWORD"
echo root:password | chpasswd

echo "Installing base pkgs"
pacman -S grub grub-btrfs efibootmgr os-prober \
	mtools dosfstools ntfs-3g nfs-utils \
	networkmanager network-manager-applet iwd wireless_tools wpa_supplicant openssh \
	parted gdisk \
	dialog xdg-user-dirs xdg-utils cups \
	bluez bluez-utils pulseaudio-bluetooth alsa-utils pavucontrol \
	bash-completion neofetch
echo "Installing GPU drivers"
#pacman -S xf86-video-qxl # Virtual Machine
#pacman -S xf86-video-intel
#pacman -S xf86-video-amdgpu
#pacman -S nvidia nvidia-utils nvidia-settings 
