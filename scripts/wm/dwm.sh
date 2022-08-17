#!/bin/sh

# VARIABLES
XKBMAP_LAYOUT=ch
XKBMAP_VARIANT_ENABLED=true
XKBMAP_VARIANT=fr
OUTPUT=eDP1
RESOLUTION=1920x1080
VANILLA_DWM=false

echo "Installing display manager"
sudo pacman -S xorg lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings

echo "Installing dwm dependencies"
sudo pacman -S nitrogen picom lxappearance \
	libx11 libxft libxinerama freetype2 fontconfig

echo "Install dwm config. repo."
cd ~/.config
mkdir dwm-session
cd dwm-session
if [ $VANILLA_DWM == false ]; then
	sudo pacman -S alacritty ttf-font-awesome
	
	GITUSER=KC5-BP
	repos=( "dmenu" "dwm" "dwmblocks" )
	for repo in ${repos[@]}
	do
		git clone https://github.com/$GITUSER/$repo
		cd $repo;make;sudo make clean install;cd ..
	done
else
	repos=( "dwm" "dmenu" "dwmstatus" "st" "slock" )
	for repo in ${repos[@]}
	do
		git clone https://git.suckless.org/$repo
		cd $repo;sudo make;sudo make clean install;cd ..
	done
fi
cd ../..

echo "Prepare xprofile"
if [ $XKBMAP_VARIANT_ENABLED == true ]; then
	cat > ~/.xprofile << EOF
# Place it under ~ OR TO SAY /home/user/.
# Keyboard layout
setxkbmap -layout $XKBMAP_LAYOUT -variant $XKBMAP_VARIANT &
# Wallpaper
nitrogen --restore &
# Compositor
picom -f &
# Display
xrandr --output $OUTPUT --mode $RESOLUTION
# Add-on
exec dwmblocks &
EOF
else
	cat > ~/.xprofile << EOF
# Place it under ~ OR TO SAY /home/user/.
# Keyboard layout
setxkbmap -layout $XKBMAP_LAYOUT &
# Wallpaper
nitrogen --restore &
# Compositor
picom -f &
# Display
xrandr --output $OUTPUT --mode $RESOLUTION
# Add-on
exec dwmblocks &
EOF
fi

echo "Prepare dwm.desktop"
if [[ ! -d /usr/share/xsessions ]]; then
	sudo mkdir /usr/share/xsessions
fi
cat > ./dwm.desktop << EOF
[Desktop Entry]
Encoding=UTF-8
Name=dwm
Comment=Dynamic Window Manager
Exec=dwm
Icon=dwm
Type=XSession
EOF
sudo mv ./dwm.desktop /usr/share/xsessions/dwm.desktop

echo "Prepare /usr/share/backgrounds folder if not existing"
if [[ ! -d /usr/share/backgrounds ]]; then
	sudo mkdir /usr/share/backgrounds
fi

sudo systemctl enable lightdm.service
