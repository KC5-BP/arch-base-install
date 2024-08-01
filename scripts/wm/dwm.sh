#!/bin/sh

# VARIABLES
XKBMAP_LAYOUT=ch
XKBMAP_VARIANT_ENABLED=true
XKBMAP_VARIANT=fr
OUTPUT_PRIMARY=eDP1
RESOLUTION=1920x1080
VANILLA_DWM=false
INSTALL_DIR=/opt/dwm_utils

echo "Installing display manager"
sudo pacman -S xorg lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings

echo "Installing dwm dependencies"
sudo pacman -S nitrogen picom lxappearance \
	libx11 libxft libxinerama freetype2 fontconfig

echo "Install dwm config. repo."
mkdir -p $INSTALL_DIR && cd $INSTALL_DIR

if [ $VANILLA_DWM == false ]; then
	sudo pacman -S ttf-font-awesome #alacritty
	
	GITUSER=KC5-BP
	repos=( "dmenu" "dwm" "dwmblocks" )
	for repo in ${repos[@]}
	do
		git clone https://github.com/$GITUSER/$repo
		cd $repo;sudo make;sudo make clean install;cd ..
	done
else
	repos=( "dwm" "dmenu" "dwmstatus" "st" "slock" )
	for repo in ${repos[@]}
	do
		git clone https://git.suckless.org/$repo
		cd $repo;sudo make;sudo make clean install;cd ..
	done
fi

echo "Prepare xprofile"
if [ $XKBMAP_VARIANT_ENABLED == true ]; then
	cat > $HOME/.xprofile << EOF
# Place it under ~ OR TO SAY /home/user/.
# Keyboard layout
setxkbmap -layout $XKBMAP_LAYOUT -variant $XKBMAP_VARIANT &
# Wallpaper
nitrogen --restore &
# Compositor
picom -f &
# Display
xrandr --output $OUTPUT_PRIMARY --primary --mode $RESOLUTION
## To COMPLETE!
## But for multiple monitors: xrandr -q to detect them
## xrandr --output $OTHER_OUTPUT --right-of $OUTPUT_PRIMARY
# Add-on
exec dwmblocks &
EOF
else
	cat > $HOME/.xprofile << EOF
# Place it under ~ OR TO SAY /home/user/.
# Keyboard layout
setxkbmap -layout $XKBMAP_LAYOUT &
# Wallpaper
nitrogen --restore &
# Compositor
picom -f &
# Display
xrandr --output $OUTPUT_PRIMARY --primary --mode $RESOLUTION
## To COMPLETE!
## But for multiple monitors: xrandr -q to detect them
## xrandr --output $OTHER_OUTPUT --right-of $OUTPUT_PRIMARY
# Add-on
exec dwmblocks &
EOF
fi

echo "Prepare dwm.desktop"
if [[ ! -d /usr/share/xsessions ]]; then
	sudo mkdir /usr/share/xsessions
fi

cat > $HOME/dwm.desktop << EOF
[Desktop Entry]
Encoding=UTF-8
Name=dwm
Comment=Dynamic Window Manager
Exec=dwm
Icon=dwm
Type=XSession
EOF
sudo mv $HOME/dwm.desktop /usr/share/xsessions/dwm.desktop

echo "Prepare /usr/share/backgrounds folder if not existing"
if [[ ! -d /usr/share/backgrounds ]]; then
	sudo mkdir /usr/share/backgrounds
fi

sudo systemctl enable lightdm.service

