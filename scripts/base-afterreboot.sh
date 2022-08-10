#!/bin/sh

echo "Are you connected to internet? [y/n]"
read ANSWER

if [ $ANSWER == y ]; then
	# VARIABLES
	COUNTRY=Switzerland
	MULTILIB_ENABLED=true
	AUR_HELPER=true
	# Using AUR_HELPER
	BTRFS_USED=true
	SWAP_WITH_ZRAM=true

	sudo timedatectl set-ntp true
	#hwclk --systohc
	sudo reflector -c $COUNTRY -a 6 --sort rate --save /etc/pacman.d/mirrorlist

	if [ $MULTILIB_ENABLED == true ]; then
		sed -i '93s/.//' /etc/pacman.conf
		sed -i '94s/.//' /etc/pacman.conf
	fi

	sudo pacman -Syyy

	if [ $AUR_HELP == true ]; then
		mkdir $HOME/Documents/buildApps
		cd $HOME/Documents/buildApps
		git clone https://aur.archlinux.org/paru.git
		cd paru/;makepkg -si --noconfirm;cd
	fi

	if [ $BTRFS_USED == true ]; then
		#paru -S timeshift-bin timeshift-autosnap
		paru -S snapper
	fi

	if [ $SWAP_WITH_ZRAM == true ]; then
		paru -S zramd
		sudo systemctl enable --now zramd.service
		sudo lsblk
	fi
elif [ $ANSWER == n ]; then
	echo "Can't update repo. and system cfg, nor install AUR_HELPER."
	echo "Script abort!"
else
	echo "Input not taken in charge.."
	echo "Script abort!"
fi

