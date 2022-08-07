# Quick review
- Distro: Arch
- Motherboard's mode: UEFI
- File System: btrfs
- Bootloader: Grub

## Installation process

Gne

## 1 Pre-Install

### 1.1 Acquire installation image : https://archlinux.org/download/
## 1.2 Verify signature
## 1.3 Prepare an installation medium (USB stick, ..)
## 1.3b Personnal comment : For dual Booting, partition from Windows your wished spaces and increase the EFI partition
## 1.4 Boot the live environment
## 1.5 Set the console keyboard layout
# List layout with 
localectl list-keymaps # You can combine this with grep 
loadkeys fr_CH-latin1
## 1.6 Verify the boot mode
ls /sys/firmware/efi/efivars	# If the path can be shown without error, then the system is in UEFI mode. 
					# Otherwise, you might have booted in MBR/BIOS mode and might look at your motherboard's manual
## 1.7 Connect to the internet
iwctl 		# Maybe useless if wired.
	device list # Usually wlan0.
	station wlan0 connect <WIRELESS_NETWORK_ID> # Prompt password to enter.
	exit
# Test connection
ping -c 5 archlinux.org
ip a
## 1.8 Update system clock
timedatectl set-ntp true
## 1.9 Partitioning
wipefs -af /dev/disk/..
parted # to mklabel gpt
gdisk /dev/nvme0n1 # Partition
lsblk
mkfs.ext4 /dev/nvme0n1p1
mkfs.btrfs /dev/nvme0n1p2

## 1.11 Mount the file systems
mount /dev/nvme0n1p2 /mnt
cd /mnt
btrfs subvolume create @
btrfs subvolume create @home
cd
umount /mnt
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@     \
/dev/nvme0n1p2 /mnt
mkdir /mnt/home
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@home \
/dev/nvme0n1p2 /mnt/home
mount --mkdir /dev/nvme0n1p1 /mnt/boot
mount --mkdir /dev/sda3      /mnt/boot/efi
lsblk

# 2 Installation
## 2.1 Select the mirrors
reflector -c Switzerland -a 6 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syyy
pacman -Syy
## 2.2 Install essential packages
pacstrap /mnt base base-devel linux linux-lts linux-headers linux-lts-headers linux-firmware nano vim git intel-ucode btrfs-progs
# Might be useless ######
rm -rf /etc/pacman.d/gnupg
umount /etc/pacman.d/gnupg
rm -rf /etc/pacman.d/gnupg
pacman-key --init && pacman-key --populate && pacman-key -r 139B09DA5BF0D338 && pacman-key --lsign-key 139B09DA5BF0D338
#########################
pacstrap /mnt base base-devel linux linux-lts linux-headers linux-lts-headers linux-firmware nano vim git intel-ucode btrfs-progs

# 3 Configure the system
## 3.1 File System TABle
genfstab -U /mnt >> /mnt/etc/fstab
# For remote ############
passwd
ip a
#########################
## 3.2 chroot
arch-chroot /mnt
vim /etc/mkinitcpio.conf
	MODULES=(btrfs)
mkinitcpio -p linux
## Base config. and packages (this can be shell scripted and executed from /)
## 3.3 Time zone
ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime
hwclk --systohc
## 3.4 Localization
sed -i '177s/.//' /etc/locale.gen # Uncomment en_US.UTF-8
sed -i '246s/.//' /etc/locale.gen # Uncomment fr_CH.UTF-8
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=fr_CH-latin1" >> /etc/vconsole.conf
## 3.5 Network configuration
echo "theMatrix" >> /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       theMatrix.localdomain   theMatrix" >> /etc/hosts
## 3.7 Root administrator
echo root:password | chpasswd
## 3.8 Base pkg
pacman -S grub grub-btrfs efibootmgr os-prober mtools dosfstools reflector networkmanager openssh iwd neofetch parted gdisk bash-completion
# If not enough space:
rm -r /var/cache/pacman/pkg/*

## 3.9 Enabling services
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable iwd
## 3.10 Boot loader (managing grub config.)
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
exit
umount -R /mnt
reboot
