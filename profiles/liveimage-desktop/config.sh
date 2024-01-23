#!/bin/bash

enable_service connman
enable_service greetd

adduser ewe video
adduser ewe input
adduser greeter video
adduser greeter input

cat <<EOF >/etc/greetd/config.toml
[terminal]
vt=1

[default_session]
command = "Hyprland"
user = "ewe"
EOF

mkdir -p /home/ewe/.config/hypr
cp /usr/share/hyprland/hyprland.conf /home/ewe/.config/hypr/hyprland.conf
sed -i 's/autogenerated=1//; s/kitty/foot/' \
	/home/ewe/.config/hypr/hyprland.conf
cp -r /etc/xdg/waybar /home/ewe/.config/waybar
sed -i 's/sway/hyprland/' /home/ewe/.config/waybar/config
cat <<EOF >>/home/ewe/.config/hypr/hyprland.conf
exec-once = waybar & swww init
EOF
chown ewe:ewe -R /home/ewe/.config
