# Modular waybar config for hyprland

![Preview](assets/waybar.png)

Waybar configs designed for hyprland  

## features  
Custom rofi menus for:  
Bluetooth  
VPN  
Volume  
Network  
Launcher/powermenu 

## Requirements
waybar  
nerd fonts (I use JetBrainsMono Nerd Font)  
Network Manager  
Bluetoothctl

This is configured for hyprland, but will work with other WM with some edits  
I use kitty/brave/thunar which can be changed  

## Install

Copy all included dirs inside of your .config dir.  
Make scripts executable   

```
git clone https://github.com/benny-e/waybar-config.git  
cd waybar-config 
```
Copy files 
```
mkdir -p ~/.config/waybar
```
Copy Scripts  
```
mkdir -p ~/.config/scripts
cp -r scripts/* ~/.config/scripts/
chmod +x ~/.config/scripts/*
```
Copy rofi themes  
```
mkdir -p ~/.config/rofi
cp -r rofi/* ~/.config/rofi/
```
