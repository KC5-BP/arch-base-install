# Quick review
- Distro: Arch
- Motherboard's mode: UEFI
- File system: btrfs
- Bootloader: Grub
- Encryption: luks

# Installation Process

Steps written following the [archwiki pages instructions](https://wiki.archlinux.org/title/Installation_guide) and following most of [EF - Made Simple](https://www.youtube.com/c/EFLinuxMadeSimple) videos.

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
localectl list-keymaps # You can combine this with grep and a keyword you're looking for
~~~

~~~shell
# In my case
loadkeys fr_CH-latin1
~~~

### 1.6 Verify the boot mode

~~~shell
ls /sys/firmware/efi/efivars # If the path can be shown without error, then the system is in UEFI mode
                             # Otherwise, you might have booted in MBR/BIOS \
                             # mode and might look at your motherboard's manual
~~~

### 1.7 Connect to the internet

~~~shell
iwctl # Maybe useless if wired.
        device list # Usually wlan0
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
hwclk --systohc # Might prompt that hwclk is not a known cmd, just ignore it
~~~

### 1.9 Partitioning

~~~shell
lsblk # Check disk blocks throughout the installation

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
cryptsetup --cipher aes-xts-plain64 --hash sha512 --use-random \
--verify-passphrase luksFormat /dev/<PARTITION_TO_ENCRYPT> # Typically root OR/AND home partition (like before, useless with btrfs)
        YES
        Entering  passphrase
        Verifying passphrase
# And before mounting an encrypted partition, you need to open it
cryptsetup luksOpen /dev/<PARTITION_ENCRYPTED> <PARTITION_ALIAS>
        Verifying passphrase
~~~

~~~shell
# Formating ..
# Remarks: add mapper to following cmds only if encrypted
# With encryption
mkfs.brfs /dev/mapper/<PARTITION_ALIAS>
# Without encryption
mkfs.brfs /dev/<PARTITION> # Typically root OR/AND home

lsblk # Check new status
~~~

### 1.11 Mount the file systems

~~~shell
mount /dev/mapper/<PARTITION_ALIAS> /mnt
# Creating sub-volumes for btrfs ######
cd /mnt
btrfs subvolume create @ # Subvolume root
btrfs subvolume create @home
cd
umount /mnt
#######################################
# Mounting subvolumes
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@ \
/dev/mapper/<PARTITION_ALIAS> /mnt
mount --mkdir -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@home \
/dev/mapper/<PARTITION_ALIAS> /mnt/home
mount --mkdir /dev/<BOOT_PARTITION> /mnt/boot # (Optional)
#mount --mkdir /dev/<EFI_PARTITION> /mnt/boot
mount --mkdir /dev/<EFI_PARTITION> /mnt/boot/efi  # If passing through (Optional)
~~~

### 1.11.bis-me Dual boot alongside Windows -> Mounting Windows partition in the Linux system

~~~shell
# Might have multiples time this if disks portioned
mkdir /mnt/windows10
mount /dev/<WIN_PARTITION> /mnt/windows10
~~~

## 2 Installation

### 2.1 Select the mirrors

~~~shell
reflector -c Switzerland -a 6 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syyy
~~~

### 2.2 Install essential packages

~~~shell
pacstrap /mnt base base-devel linux linux-lts linux-headers linux-lts-headers \
linux-firmware nano vim git btrfs-progs reflector \ 
intel-ucode # Intel processor
#amd-ucode  # AMD processor
# Last one might cause error because already installed.

# If getting marginal trust issue ##
rm -rf /etc/pacman.d/gnupg
umount /etc/pacman.d/gnupg
rm -rf /etc/pacman.d/gnupg
pacman-key --init && pacman-key --populate && \
pacman-key -r 139B09DA5BF0D338 && pacman-key --lsign-key 139B09DA5BF0D338 
# Might (or not) need to update the <GPG_KEY> in the future
####################################
# Redoing pacstrap ..
~~~

## 3 Configure the system

### 3.1 File System TABle

~~~shell
genfstab -U /mnt >> /mnt/etc/fstab
~~~

### 3.2 chroot

~~~shell
arch-chroot /mnt
~~~

### 3.2.bis-me Modify /etc/mkinitcpio.cong for btrfs and encryption ####

~~~shell
vim /etc/mkinitcpio.conf
        MODULES=(btrfs)
        # IF Encrypted
        HOOKS=(base udev "other_default_gibberish" .. encrypt filesystems \
keyboard fsck) # "encrypt" MUST BE BEFORE "filesystems"
~~~

### 3.6 Initramfs (Normally, but has no other influence on the following steps)

~~~shell
mkinitcpio -p linux
~~~

## 3.follow-up Base config. and packages

Will provide a script for that ...

### 3.3 Time zone

~~~shell
ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime
hwclk --systohc # Might prompt that hwclk is not a known cmd, just ignore it
~~~

### 3.4 Localization

~~~shell
sed -i '177s/.//' /etc/locale.gen # Uncomment line 177, being en_US.UTF-8
sed -i '246s/.//' /etc/locale.gen # Same for fr_CH.UTF-8
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=fr_CH-latin1" >> /etc/vconsole.conf
~~~

### 3.5 Network configuration

~~~shell
echo "theShipwreck" >> /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       theShipwreck.localdomain        theShipwreck" >> \
/etc/hosts
~~~

### 3.6 Test it out ... 

Redoing a mkinitcpio -p linux # Will it allow the passphrase's encrypted disk to be entered with the set KEYMAP and not the default one ??

### 3.7 Root administrator

~~~shell
echo root:password | chpasswd # format user:userpassword injected to chpasswd
~~~

### 3.8 Base pkg

~~~shell
pacman -S grub grub-btrfs efibootmgr os-prober \
mtools dosfstools ntfs-3g nfs-utils \
networkmanager network-manager-applet iwd wireless_tools wpa_supplicant openssh \
parted gdisk \
dialog xdg-user-dirs xdg-utils cups \
bluez bluez-utils pulseaudio-bluetooth alsa-utils pavucontrol \
bash-completion neofetch\
# If getting marginal trust issue ##
rm -rf /etc/pacman.d/gnupg
umount /etc/pacman.d/gnupg
rm -rf /etc/pacman.d/gnupg
pacman-key --init && pacman-key --populate && \
pacman-key -r 139B09DA5BF0D338 && pacman-key --lsign-key 139B09DA5BF0D338 
# Might (or not) need to update the <GPG_KEY> in the future
# Kept part with -r & --lsign-key to avoid any errors while updating or else the pkg that needed it
####################################

# GPU pkg
#pacman -S --no-confirm xf86-video-qxl # VirtualMachine
#pacman -S --no-confirm xf86-video-intel mesa
#pacman -S --no-confirm xf86-video-amdgpu
#pacman -S --no-confirm nvidia nvidia-utils nvidia-settings
~~~

### 3.9 Enabling services

~~~shell
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable sshd
systemctl enable cups
systemctl enable iwd
systemctl enable reflector.timer
~~~

### 3.10 Creating a "default" user

~~~shell
useradd -m user # Could add G wheel
echo user:password | chpasswd
echo "user ALL=(ALL) ALL" >> /etc/sudoers.d/user
~~~

### 3.8 Boot loader (Normally, but 3.{8..10} prevent to be done at 1st boot from root)

~~~shell
rm -rf /boot/PATH/TO/PREVIOUS/GRUB # Remove previous if needed
grub-install --target=x86_64-efi --efi-directory=/boot(/efi) \
--bootloader-id=<BOOTLOADER_DIR_NAME>
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg 
# When dual booting, inject the content of it in the /etc/grub.d/40_custom from the system that manage the bootloader

# IF ENCRYPTED
# Find block id with blkid /dev/<DISK_ENCRYPTED>
vim /etc/default/grub
        GRUB_CMDLINE_LINUX="cryptdevice=UUID=xxxx-x-x-xx:<PARTITION_ALIAS> \
root=/dev/mapper/<PARTITION_ALIAS>"
grub-mkconfig -o /boot/grub/grub.cfg

printf "\e[1,32mDone! Type exit -> umount -a & reboot\n\e[0m"

exit # .. of arch-chroot
umount -R /mnt
reboot
~~~

## Personal notes: 

To remount afterwards:

~~~shell
# IF ENCRYPTED (this case with luks)
cryptsetup luksOpen /dev/<DISK_ENCRYPTED> <PARTITION_ALIAS>
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@ \
/dev/mapper/<PARTITION_ALIAS> /mnt
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@home \
/dev/mapper/<PARTITION_ALIAS> /mnt/home
mount --mkdir /dev/<BOOT_PARTITION> /mnt/boot # (Optional)
mount --mkdir /dev/<EFI_PARTITION> /mnt/boot(/efi)  # If passing through (Optional)
~~~

# 4 Post-installation (config. add-on only)

After (re-)booting, need passphrase to access encrypted partition

Then login (user + password)

## First steps

### Reconnecting to wifi (if wireless)

~~~shell
nmtui
        Activate a connection
                Check network connectivity
                BACK
        QUIT
ip a
~~~

### Enabling multilib & reload fastest mirrors

~~~shell
# Uncomment it in
vim /etc/pacman.conf
sudo reflector -c Switzerland -a 12 --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Syyu
~~~

### Get an AUR helper (or not, I recommend it after you understand what's happening in the background)

~~~shell
git clone https://aur.archlinux.org/paru-bin
cd paru-bin
makepkg -si
~~~

### Using btrfs, get a snapshot mngr (& while at it, our swapfile mngr instead of making it "à la mano'")

~~~shell
paru -S snapper zramd
# OR
paru -S timeshift-bin timeshift-autosnap zramd

systemctl enable --now zramd.service
lsblk # Should see the swap virtual disk
~~~

## An environment (DE or WM)

For that check some of the script put at disposal:
- d
- d
- d

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
