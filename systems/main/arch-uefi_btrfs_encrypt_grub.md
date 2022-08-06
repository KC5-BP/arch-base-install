# Quick review
- Distro: Arch
- Motherboard's mode: UEFI
- File system: btrfs
- Bootloader: Grub
- Encryption: luks

# Installation Process

Steps written following the [archwiki pages instructions](https://wiki.archlinux.org/title/Installation_guide) and following most of [EF - Made Simple](https://www.youtube.com/c/EFLinuxMadeSimple).

## 1 Pre-Install

### 1.1 Acquire installation image : 

From https://archlinux.org/download/

### 1.2 Verify signature

~~~shell
gpg --keyserver-options auto-key-retrieve --verify archlinux-version-x86_64.iso.sig
~~~

### 1.3 Prepare an installation medium (USB stick, ..)

Using for example balenaEtcher or else ..

### 1.3.bis-me For dual Booting

Prepare wished partitions from Windows, additionally increasing the EFI partition is a clever move.

### 1.4 Boot the live environment

### 1.5 Set the console keyboard layout

~~~shell
localectl list-keymaps # You can combine this with grep and a keyword you're looking for.
~~~

~~~shell
# In my case
loadkeys fr_CH-latin1
~~~

### 1.6 Verify the boot mode

~~~shell
ls /sys/firmware/efi/efivars # If the path can be shown without error, then the system is in UEFI mode.
                             # Otherwise, you might have booted in MBR/BIOS mode and might look at your motherboard's manual.
~~~

### 1.7 Connect to the internet

~~~shell
iwctl # Maybe useless if wired.
        device list # Usually wlan0.
	station <DEVICE> connect <WIRELESS_NETWORK_ID> 
      # Prompt password to enter, so enter it ..
	exit
# Test connection
ping -c 5 archlinux.org
ip a
~~~

### 1.8 Update system clock

~~~shell
timedatectl set-ntp true
hwclk --systohc # Might prompt that hwclk is not a known cmd, just ignore it.
~~~

### 1.9 Partitioning

~~~shell
lsblk # Check disk blocks throughout the installation.
# Clean old partition (in case of a re-installation) / disk
# /!\ CLEAN ONLY WHAT'S NEEDED /!\
wipefs -af /dev/<PARTITION_TO_CLEAN>
wipefs -af /dev/<DISK_TO_CLEAN>

parted # Just used to make label on the disk
        sel /dev/<DISK_TO_MAKE_TABLE>
        mklabel gpt
# I personally prefer gdisk than parted to portion the disk
gdisk /dev/<DISK_TO_MAKE_INSTALL> # sda, sdb, nvme0n1, ..
# Typical partition to define : efi, boot (Optional), root, home (root + home useless with btrfs though)
	n (New)
	First sector: (usually leave it by default)
	Last sector:  (simpler ex.: +300M)
	HEX Code:     ef00 (EFI), 8300 (default Linux filesystem)
	w (Write)
	Y
lsblk # Check new status
~~~

### 1.10 Format the partition

~~~shell
mkfs.ext4 /dev/<BOOT_PARTITION> # (Optional if not doing a boot partition)

# Might be useless if dual booting and prepared from Windows
mkfs.fat -FAT32 /dev/<EFI_PARTITION>
~~~

### 1.10.bis-me Using encryption there's plenty of solutions out there, this is one example:

~~~shell
cryptsetup --cipher aes-xts-plain64 --hash sha512 --use-random --verify-passphrase luksFormat /dev/<PARTITION_TO_ENCRYPT> # Typically root OR/AND home partition
        YES
        Entering  passphrase
        Verifying passphrase
# Opening encrypted partition
cryptsetup luksOpen /dev/<PARTITION_ENCRYPTED> <PARTITION_ALIAS>
        Verifying passphrase

# Remarks for the following cmd, add mapper only if encrypted
# With encryption
mkfs.brfs /dev/mapper/<PARTITION_ALIAS>
# Without encryption
mkfs.brfs /dev/<PARTITION> # Typically root

lsblk # Check new status

## 1.11 Mount the file systems
mount /dev/mapper/<PARTITION_ALIAS> /mnt
# Creating sub-volumes for btrfs ######
cd /mnt
btrfs subvolume create @ # Subvolume root
btrfs subvolume create @home
cd
umount /mnt
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@ /dev/mapper/<PARTITION_ALIAS> /mnt
mount --mkdir -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@home /dev/mapper/<PARTITION_ALIAS> /mnt/home
mount --mkdir /dev/<BOOT_PARTITION> /mnt/boot # (Optional)
mount --mkdir /dev/<EFI_PARTITION> /mnt/boot
mount --mkdir /dev/<EFI_PARTITION> /mnt/boot/efi  # If passing through (Optional)
### Personal comment : Accessing Windows files from Linux (Optionnal and from dual booting)
# Might have multiples time this if disks portioned
mkdir /mnt/windows10
mount /dev/<WIN_PARTITION> /mnt/windows10

# 2 Installation
## 2.1 Select the mirrors
reflector -c Switzerland -a 6 --sort rate --save /etc/pacman.d/mirrorlist
# Uncomment multilib in /etc/pacman.conf
pacman -Syyy
## 2.2 Install essential packages
# Intel processor
pacstrap /mnt base base-devel linux linux-lts linux-headers linux-lts-headers linux-firmware nano vim git btrfs-progs reflector intel-ucode # Last one might cause error because already installed.
# AMD processor
pacstrap /mnt base base-devel linux linux-lts linux-headers linux-lts-headers linux-firmware nano vim git btrfs-progs reflector amd-ucode # Last one might cause error because already installed.
# Might be useless ######
rm -rf /etc/pacman.d/gnupg
umount /etc/pacman.d/gnupg
rm -rf /etc/pacman.d/gnupg
pacman-key --init && pacman-key --populate && pacman-key -r 139B09DA5BF0D338 && pacman-key --lsign-key 139B09DA5BF0D338
#########################
pacstrap /mnt base base-devel build-essential linux linux-lts linux-headers linux-lts-headers linux-firmware nano vim git intel-ucode btrfs-progs # OR amd-ucode
# 3 Configure the system
## 3.1 File System TABle
genfstab -U /mnt >> /mnt/etc/fstab
# Output like :
# └─$> cat /mnt/etc/fstab
# /dev/<MOUNTED_POINT>
# UUID=	/			ext4		...		01
# 		/boot			vfat		...		02
# 		/windows10		ntfs		...		00
## 3.2 chroot
arch-chroot /mnt
## 3.2b Personal comment : Specific to btrfs and encryption ###
vim /etc/mkinitcpio.conf
	MODULES=(btrfs)
	# IF Encrypted
	HOOKS=(base udev blablabla .. encrypt filesystems keyboard fsck) # MUST BE BEFORE "filesystems"
# Try settings keyboard before encrypt just to see if I can enter my password with fr_CH-latin1 layout
## 3.6 -> 3.2c : Personal note : Some cmd can be done in any order
mkinitcpio -p linux
## ############################################################

## Base config. and packages (this can be shell scripted and executed from /)
## 3.3 Time zone
ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime
hwclk --systohc
## 3.4 Localization
# Delete the first character on line X (in this case, it uncomments the line 178)
sed -i '177s/.//' /etc/locale.gen # Uncomment en_US.UTF-8
sed -i '246s/.//' /etc/locale.gen # Uncomment fr_CH.UTF-8
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=fr_CH-latin1" >> /etc/vconsole.conf
## 3.5 Network configuration
echo "theShipwreck" >> /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       theShipwreck.localdomain        theShipwreck" >> /etc/hosts
## 3.7 Root administrator
echo root:password | chpasswd # root being the user to change password from and obviously password, the attributed one

## 3.8 Base pkg
# Personal: Uncomment multilib in /etc/pacman.conf
pacman -S grub grub-btrfs efibootmgr os-prober mtools dosfstools reflector networkmanager network-manager-applet openssh iwd parted gdisk bash-completion neofetch ntfs-3g nfs-utils wireless_tools wpa_supplicant dialog xdg-user-dirs xdg-utils bluez bluez-utils pulseaudio-bluetooth cups alsa-utils pavucontrol
# Workaround if needed ##
rm -rf /etc/pacman.d/gnupg
umount /etc/pacman.d/gnupg
rm -rf /etc/pacman.d/gnupg
pacman-key --init && pacman-key --populate && pacman-key -r 139B09DA5BF0D338 && pacman-key --lsign-key 139B09DA5BF0D338
#########################
# GPU pkg
#pacman -S --no-confirm xf86-video-qxl # VirtualMachine
#pacman -S --no-confirm xf86-video-intel mesa
#pacman -S --no-confirm xf86-video-amdgpu
#pacman -S --no-confirm nvidia nvidia-utils nvidia-settings
## 3.9 Enabling services
systemctl enable NetworkManager # OR iwd
systemctl enable bluetooth
systemctl enable cups
systemctl enable sshd
systemctl enable reflector.timer
## 3.10 Creating a "default" user
useradd -m user # Could add G wheel
echo user:password | chpasswd
echo "user ALL=(ALL) ALL" >> /etc/sudoers.d/user
## 3.8 -> 3.11 Boot loader (managing grub config.)
rm -rf /boot/efi/EFI/GRUB # Remove previous if needed
grub-install --target=x86_64-efi --efi-directory=/boot(/efi) --bootloader-id=<BOOTLOADER_NAME> # That will appear on your efi partition
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg # When dual booting, use this file injected with cat 
# IF ENCRYPTED
# Find block id with blkid /dev/<DISK_ENCRYPTED>
vim /etc/default/grub
	GRUB_CMDLINE_LINUX="cryptdevice=UUID=xxxx-x-x-xx:<PARTITION_ALIAS> root=/dev/mapper/<PARTITION_ALIAS>"
grub-mkconfig -o /boot/grub/grub.cfg

printf "\e[1,32mDone! Type exit -> umount -a & reboot\n\e[0m"

exit
umount -R /mnt OR umount -a
reboot

## Personal note: to remount afterwards :
##IF ENCRYPTED (ex. with luks encryption)
cryptsetup luksOpen /dev/<DISK_ENCRYPTED> <PARTITION_ALIAS>
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@ /dev/mapper/<PARTITION_ALIAS> /mnt
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@home /dev/mapper/<PARTITION_ALIAS> /mnt/home
mount --mkdir /dev/<BOOT_PARTITION> /mnt/boot # (Optional)
mount --mkdir /dev/<EFI_PARTITION> /mnt/boot(/efi)  # If passing through (Optional)

# 4 Post-installation
After (re-)booting, need passphrase to access encrypted partition
Then login (user + password)
# If delogged from network
nmtui
	Activate a connection
		Check network connectivity
		BACK
	QUIT
ip a

# Enable multilib by uncommenting it in /etc/pacman.conf
sudo pacman -Syyu
# Get fastest mirrors
sudo reflector -c Switzerland -a 12 --sort rate --save /etc/pacman.d/mirrorlist

git clone https://aur.archlinux.org/paru-bin
cd paru-bin
makepkg -si

paru -S snapper

# Manually manage snapshot
Remark(s):
Config of subvolumes are under /etc/snapper/configs/<CONFIG_NAME>
Snapshots of subvolumes are under the subvolumes directory 
For instance: Snapshots of / are under /.snapshots
		  Those of /home are under /home/.snapshots
# Create a config. for a subvolume
snapper -c <CONFIG_NAME> create-config /PATH/TO/SUBVOL # Leave only / for root
# Create a snapshot
snapper -c <CONFIG_NAME> create -d "DESCRIPTION"
# List config's snapshots
snapper -c <CONFIG_NAME> list
# Compare snapshots
snapper -c <CONFIG_NAME> diff n1..n2
# Undo changes between snapshots
snapper -c <CONFIG_NAME> undochange n1..n2 # /!\ Order between nx is important
							 # If 1..2 Create files
							 # Then 2..1 Delete them!
							 # Can be seen as pseudo-rollback
							 # Check what I made and the consequences ...
# Delete snapshot "n"
snapper -c <CONFIG_NAME> delete n
# Delete config
snapper -c <CONFIG_NAME> delete-config


# Timeshift & zram (alternativ to manually "makeswap")
paru -S timeshift-bin timeshift-autosnap zramd #brave-bin # Don't use timeshift if using snapper to avoid having 2 snapshotters
sudo systemctl enable --now zram.service
lsblk # Should shown the swap partition



# Display manager, wm & browser
sudo pacman -S xorg lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings qutebrowser
# For my personal DWM
ttf-font-awesome nitrogen picom lxappearance libx11 libxft libxinerama freetype2 fontconfig
#sudo pacman -S opera opera-ffmpeg-codecs
sudo systemctl enable lightdm.service
sudo pacman 

# Personal note : 
- swap made with zramd
- For multiple boot between Linux distros using btrfs : To separate home and root partitions, a solution is to set the $HOME var. pointing to a specific partition created especially for this purpose.
