#!/bin/sh

# VARIABLES
LANGUAGE=en_US.UTF-8
KEYMAP_LAYOUT=fr_CH-latin1
HOSTNAME=mmmmmh
BOOTLOADER_DIR_NAME=ArchSys
ENCRYPTED=true

echo "Setting up TIME ZONE"
ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime

#echo "Setting up DATE & CLOCK to hardware"
#hwclk --systohc

echo "Setting up LOCALIZATION"
echo "For $LANGUAGE"
sed -i '177s/.//' /etc/locale.gen 
echo "For fr_CH.UTF-8"
sed -i '246s/.//' /etc/locale.gen
locale-gen
echo "Putting language in locale.conf"
echo "LANG=$LANGUAGE" >> /etc/locale.conf
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
	parted gdisk tlp \
	dialog xdg-user-dirs xdg-utils cups \
	bluez bluez-utils pulseaudio-bluetooth alsa-utils pavucontrol \
	bash-completion neofetch
echo "Workaround if pacman failed because of marginal trust"
rm -rf /etc/pacman.d/gnupg
pacman-key --init && pacman-key --populate && \
	pacman-key -r 139B09DA5BF0D338 && pacman-key --lsign-key 139B09DA5BF0D338 
echo "2nd try on installing  base pkgs"
pacman -S grub grub-btrfs efibootmgr os-prober \
	mtools dosfstools ntfs-3g nfs-utils \
	networkmanager network-manager-applet iwd wireless_tools wpa_supplicant openssh \
	parted gdisk tlp \
	dialog xdg-user-dirs xdg-utils cups \
	bluez bluez-utils pulseaudio-bluetooth alsa-utils pavucontrol \
	bash-completion neofetch

echo "Installing GPU drivers"
#pacman -S xf86-video-qxl # Virtual Machine
#pacman -S xf86-video-intel mesa
#pacman -S xf86-video-amdgpu
#pacman -S nvidia nvidia-utils nvidia-settings 

echo "Enabling services"
systemctl enable NetworkManager
systemctl enable bluetooth 
systemctl enable cups
systemctl enable sshd 
systemctl enable iwd 
systemctl enable tlp
systemctl enable reflector.timer

echo "Creating a basic user"
useradd -m user
echo user:password | chpasswd
#usermod -aG <GROUPS> user # If needed to add user to a specific group
echo "user ALL=(ALL) ALL" >> /etc/sudoers.d/user

echo "Creating bootloader"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=$BOOTLOADER_DIR_NAME
echo "Enabling OS_PROBER & Creating config. file"
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

if [ $ENCRYPTED == true ]; then
	echo "Need to add to GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=<UUID_OF_ENCRYPTED_DISK>:<PARTITION_ALIAS> root=/dev/mapper/<PARTITION_ALIAS>\""
	echo "Then redo the grub-mkconfig cmd"
fi

printf "\e[1;32mDone! Type exit -> unmount devices & reboot\n\e[0m"

