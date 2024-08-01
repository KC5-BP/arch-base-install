#!/bin/sh

# VARIABLES
LANGUAGE=en_US.UTF-8
KEYMAP_LAYOUT=fr_CH-latin1
HOSTNAME=theShipwreck
BOOTLOADER_DIR_NAME=shipwreckGrub
BASIC_USR=deep
ENABLE_OS_PROBER=true
ENCRYPTED=false

echo "Setting up TIME ZONE"
ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime

#echo "Setting up DATE & CLOCK to hardware"
hwclock --systohc

echo "Setting up LOCALIZATION"
echo "For $LANGUAGE"
sed -i '171s/.//' /etc/locale.gen 
echo "For fr_CH.UTF-8"
sed -i '240s/.//' /etc/locale.gen
locale-gen
echo "Putting language in locale.conf"
echo "LANG=$LANGUAGE" >> /etc/locale.conf
echo "Putting keyboard layout in vconsole.conf"
echo "KEYMAP=$KEYMAP_LAYOUT" >> /etc/vconsole.conf

echo "Setting up HOSTNAME & NETWORK CFG"
echo "$HOSTNAME" >> /etc/hostname
echo "127.0.0.1		localhost" >> /etc/hosts
echo "::1		localhost" >> /etc/hosts
echo "127.0.1.1		$HOSTNAME.localdomain	$HOSTNAME" >> /etc/hosts

echo "Setting up ROOT PASSWORD"
echo root:password | chpasswd

pacman-key --init && pacman-key --populate

echo "Installing base pkgs"
pacman -S grub efibootmgr os-prober \
	mtools dosfstools ntfs-3g nfs-utils \
	iwd networkmanager network-manager-applet openssh wireless_tools wpa_supplicant \
	gdisk parted tlp \
	cups dialog xdg-user-dirs xdg-utils \
	alsa-utils alsa-oss bluez bluez-utils pulseaudio-bluetooth pavucontrol \
	bash-completion neofetch \
	cmake gdb ninja
#echo "Workaround if pacman failed because of marginal trust"
#rm -rf /etc/pacman.d/gnupg
#pacman-key --init && pacman-key --populate && \
#	pacman-key -r 139B09DA5BF0D338 && pacman-key --lsign-key 139B09DA5BF0D338 
#echo "2nd try on installing  base pkgs"
#pacman -S grub grub-btrfs efibootmgr os-prober \
#	mtools dosfstools ntfs-3g nfs-utils \
#	iwd networkmanager network-manager-applet openssh wireless_tools wpa_supplicant \
#	gdisk parted tlp \
#	cups dialog xdg-user-dirs xdg-utils \
#	alsa-utils bluez bluez-utils pulseaudio-bluetooth pavucontrol \
#	bash-completion neofetch \
#	cmake gdb nodejs

echo "Installing GPU drivers"
#pacman -S xf86-video-qxl # Virtual Machine
pacman -S xf86-video-intel mesa
#pacman -S xf86-video-amdgpu
pacman -S nvidia nvidia-utils nvidia-settings 

echo "Enabling services"
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups
systemctl enable sshd
systemctl enable iwd
systemctl enable tlp
systemctl enable reflector.timer

echo "Creating a basic user"
useradd -m $BASIC_USR
echo $BASIC_USR:password | chpasswd
usermod -aG wheel $BASIC_USR # If needed to add user to a specific group
echo "$BASIC_USR ALL=(ALL) ALL" >> /etc/sudoers.d/$BASIC_USR

echo "Creating bootloader"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=$BOOTLOADER_DIR_NAME
if [ $ENABLE_OS_PROBER == true ]; then
	echo "Enabling OS_PROBER & Creating config. file"
	echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
else
	echo "Creating config. file"
fi
grub-mkconfig -o /boot/grub/grub.cfg

if [ $ENCRYPTED == true ]; then
	echo "Need to add to GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=<UUID_OF_ENCRYPTED_DISK>:<PARTITION_ALIAS> root=/dev/mapper/<PARTITION_ALIAS>\""
	echo "Then redo the grub-mkconfig cmd"
fi

printf "\e[1;32mDone! Type exit -> unmount devices & reboot\n\e[0m"

