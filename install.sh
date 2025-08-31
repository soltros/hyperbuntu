#!/bin/bash

# --- User and Environment Variables ---
# The username for which to apply the configurations
USERNAME="derrik"

# --- Update and Install Required Packages ---
# Update package lists and install necessary dependencies
sudo apt update
sudo apt install -y build-essential curl git
sudo apt install -y gnome-keyring papirus-icon-theme gnome-themes-extra

# Install Hyprland from a PPA as it's not in the default repos
sudo add-apt-repository ppa:hyprland-dev/hyprland -y
sudo apt update

# Install all the packages from your NixOS flake
sudo apt install -y \
  code \
  htop \
  btop \
  ripgrep \
  fd-find \
  wofi \
  rofi \
  swaybg \
  swaylock \
  swayidle \
  nemo \
  pamixer \
  playerctl \
  network-manager-gnome \
  pavucontrol \
  wl-clipboard \
  grim \
  slurp \
  jq \
  wlogout \
  seahorse \
  fonts-ubuntu \
  fonts-firacode \
  alacritty \
  hyprland \
  mako \
  zsh-autosuggestions \
  zsh-syntax-highlighting

# Install Nerd Fonts by cloning the official repository
echo "Installing Nerd Fonts..."
NERD_FONTS_DIR="/tmp/nerd-fonts-temp"
git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git "$NERD_FONTS_DIR"
sudo -u "$USERNAME" sh -c "cd $NERD_FONTS_DIR && ./install.sh FiraCode"
rm -rf "$NERD_FONTS_DIR"

# --- SDDM Setup ---
echo "Setting up SDDM login manager."
# Install SDDM. The Hyprland package already includes the necessary .desktop file.
sudo apt install -y sddm

# Enable SDDM as the display manager
sudo systemctl enable sddm

# --- User-Specific Configurations (for USERNAME) ---
# Ensure user is set and home directory exists
if ! id "$USERNAME" &>/dev/null; then
  echo "User '$USERNAME' does not exist. Please create the user before running this script."
  exit 1
fi

# Set the home directory path
HOME_DIR="/home/$USERNAME"

# Set up Git configuration
sudo -u "$USERNAME" git config --global user.name "Derrik Diener"
sudo -u "$USERNAME" git config --global user.email "soltros@proton.me"
sudo -u "$USERNAME" git config --global init.defaultBranch "main"
sudo -u "$USERNAME" git config --global pull.rebase true
sudo -u "$USERNAME" git config --global core.editor "nano"

# --- Zsh and oh-my-zsh Setup ---
sudo apt install -y zsh
sudo usermod --shell /usr/bin/zsh "$USERNAME"

# Switch to the user to run oh-my-zsh installation
sudo -u "$USERNAME" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Edit .zshrc with aliases and functions
ZSHRC_FILE="$HOME_DIR/.zshrc"
# Add your environment variables, aliases, and functions to the ZSHRC file
sudo -u "$USERNAME" tee -a "$ZSHRC_FILE" > /dev/null <<'EOT'

# Environment Variables
export LANG=en_US.UTF-8
export PATH="$PATH:$HOME_DIR/.local/bin"

# Alias
alias pkrun='pkexec env WAYLAND_DISPLAY=$WAYLAND_DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR'

# Functions
update-packages() {
  sudo apt update && sudo apt full-upgrade -y
}

# The Nix-specific functions cannot be converted directly, so they're replaced with
# a note and simple 'apt' commands.
nix_operations() {
  echo "Nix-specific functions like 'nix_operations' are not available on Ubuntu."
  echo "Use 'apt' commands instead. For example:"
  echo "  update: 'sudo apt update && sudo apt full-upgrade -y'"
  echo "  install: 'sudo apt install <package>'"
  echo "  uninstall: 'sudo apt remove <package>'"
  return 1
}
nixsearch() {
  echo "Use 'apt search <package>' instead of nix-env."
  return 1
}
search_nixpkg() {
  echo "Use 'apt search <package>' or 'apt-cache search <package>' instead of nix search."
  return 1
}
EOT

# --- Home Manager File Creations ---
# Create Waybar configuration and style files
WAYBAR_CONFIG_DIR="$HOME_DIR/.config/waybar"
sudo -u "$USERNAME" mkdir -p "$WAYBAR_CONFIG_DIR"
sudo -u "$USERNAME" tee "$WAYBAR_CONFIG_DIR/config" > /dev/null <<'EOT'
{
  "layer": "top",
  "position": "bottom",
  "height": 24,
  "modules-left": ["custom/launcher", "hyprland/workspaces", "sway/mode", "custom/spotify"],
  "modules-center": ["sway/window"],
  "modules-right": ["pulseaudio", "battery", "tray", "clock", "custom/power"],
  "custom/launcher": {
    "format": "◉",
    "tooltip": false,
    "on-click": "~/.local/bin/launch-apps"
  },
  "hyprland/workspaces": {
    "disable-scroll": false,
    "all-outputs": true,
    "format": "{icon} {name}",
    "format-icons": {
      "1": "", "2": "", "3": "", "4": "", "5": "",
      "6": "", "7": "", "8": "", "9": "", "10": "",
      "urgent": "Urgent",
      "focused": "Focused",
      "default": ""
    },
    "on-scroll-up": "hyprctl dispatch workspace e+1",
    "on-scroll-down": "hyprctl dispatch workspace e-1",
    "on-click": "activate"
  },
  "sway/mode": {
    "format": "<span style=\"italic\">{}</span>"
  },
  "tray": {
    "spacing": 10
  },
  "clock": {
    "format": "{:%I:%M %p}",
    "format-alt": "{:%Y-%m-%d}"
  },
  "battery": {
    "bat": "BAT0",
    "states": {
      "warning": 30,
      "critical": 15
    },
    "format": "{capacity}% {icon}"
  },
  "pulseaudio": {
    "format": "{volume}% {icon}",
    "format-bluetooth": "{volume}% {icon}",
    "format-muted": "",
    "format-icons": {
      "headphones": "", "handsfree": "", "headset": "",
      "phone": "", "portable": "", "car": "",
      "default": ["", ""]
    },
    "on-click": "pavucontrol"
  },
  "custom/spotify": {
    "format": " {}",
    "max-length": 40,
    "interval": 30,
    "exec": "$HOME_DIR/.config/waybar/mediaplayer.sh",
    "exec-if": "pgrep spotify"
  },
  "custom/power": {
    "format": "⏻",
    "tooltip": false,
    "on-click": "wlogout"
  }
}
EOT

sudo -u "$USERNAME" tee "$WAYBAR_CONFIG_DIR/style.css" > /dev/null <<'EOT'
* {
  border: none;
  border-radius: 0;
  font-family: "Fira Code Symbols";
  font-size: 13px;
  min-height: 0;
  font-weight: bold;
}
window#waybar {
  background: #000000;
  color: #cba6f7;
  border-radius: 1px 1px 0 0;
}
#window {
  font-family: "Ubuntu";
  color: #cba6f7;
}
#workspaces button {
  padding: 0 5px;
  background: transparent;
  color: #cba6f7;
  border-bottom: 2px solid transparent;
}
#workspaces button.focused {
  color: #cba6f7;
  border-bottom: 2px solid #cba6f7;
  background-color: rgba(203, 166, 247, 0.1);
}
#mode {
  background: #6c7086;
  border-top: 3px solid #cba6f7;
  color: #cba6f7;
}
#clock, #battery, #cpu, #memory, #network, #pulseaudio, #custom-spotify, #tray, #mode {
  padding: 0 3px;
  margin: 0 2px;
  color: #cba6f7;
}
#network.disconnected {
  background: #f53c3c;
}
#custom-spotify {
  color: rgb(102, 220, 105);
}
#custom-launcher {
  color: #cba6f7;
  font-size: 16px;
  font-weight: bold;
  margin-left: 8px;
  margin-right: 4px;
  padding: 0 6px;
  background-color: rgba(203, 166, 247, 0.1);
  border-radius: 4px;
}
#custom-power {
  color: #cba6f7;
  font-size: 14px;
  margin-left: 4px;
  margin-right: 8px;
  padding: 0 6px;
  background-color: rgba(203, 166, 247, 0.1);
  border-radius: 4px;
}
#battery.warning:not(.charging) {
  color: white;
  animation-name: blink;
  animation-duration: 0.5s;
  animation-timing-function: linear;
  animation-iteration-count: infinite;
  animation-direction: alternate;
}
EOT

# Create Mako configuration
MAKO_CONFIG_DIR="$HOME_DIR/.config/mako"
sudo -u "$USERNAME" mkdir -p "$MAKO_CONFIG_DIR"
sudo -u "$USERNAME" tee "$MAKO_CONFIG_DIR/config" > /dev/null <<'EOT'
anchor=top-right
margin=10
max-visible=5
default-timeout=5000
font=Sans 10
background-color=#1e1e1e
text-color=#ffffff
border-size=0
border-color=#1e1e1e
on-notify=exec makoctl menu wofi -d -p 'Choose Action: '
EOT

# Create Rofi theme file
ROFI_CONFIG_DIR="$HOME_DIR/.config/rofi"
sudo -u "$USERNAME" mkdir -p "$ROFI_CONFIG_DIR"
sudo -u "$USERNAME" tee "$ROFI_CONFIG_DIR/custom.rasi" > /dev/null <<'EOT'
* {
  background-color: transparent;
  text-color: #cba6f7;
  font: "FiraCode Nerd Font 12";
}
window {
  background-color: #1e1e2e;
  border: 2px;
  border-color: #cba6f7;
  border-radius: 10px;
  padding: 10px;
  width: 400px;
}
inputbar {
  background-color: #313244;
  border-radius: 5px;
  padding: 8px;
  margin: 0px 0px 10px 0px;
  spacing: 8px;
}
prompt {
  enabled: false;
}
entry {
  placeholder: "Search applications...";
  placeholder-color: #6c7086;
}
listview {
  background-color: transparent;
  spacing: 2px;
  lines: 8;
  columns: 1;
}
element {
  background-color: transparent;
  border-radius: 5px;
  padding: 8px;
}
element selected {
  background-color: #585b70;
}
element-icon {
  size: 32px;
  margin: 0px 8px 0px 0px;
}
EOT

# Create Wofi configuration and style
WOFI_CONFIG_DIR="$HOME_DIR/.config/wofi"
sudo -u "$USERNAME" mkdir -p "$WOFI_CONFIG_DIR"
sudo -u "$USERNAME" tee "$WOFI_CONFIG_DIR/config" > /dev/null <<'EOT'
width=400
height=500
location=bottom-left
show=drun
prompt=Applications
filter_rate=100
allow_markup=true
no_actions=true
halign=fill
orientation=vertical
content_halign=fill
insensitive=true
allow_images=true
image_size=40
gtk_dark=true
EOT

sudo -u "$USERNAME" tee "$WOFI_CONFIG_DIR/style.css" > /dev/null <<'EOT'
window {
  margin: 0px;
  border: 2px solid #cba6f7;
  background-color: #1e1e2e;
  border-radius: 10px;
}
#input {
  margin: 5px;
  border: 2px solid #313244;
  color: #cdd6f4;
  background-color: #313244;
  border-radius: 8px;
  padding: 8px;
  font-size: 14px;
}
#inner-box {
  margin: 5px;
  border: none;
  background-color: #1e1e2e;
  border-radius: 8px;
}
#outer-box {
  margin: 5px;
  border: none;
  background-color: #1e1e2e;
  border-radius: 8px;
}
#scroll {
  margin: 0px;
  border: none;
}
#text {
  margin: 5px;
  border: none;
  color: #cdd6f4;
}
#entry {
  border-radius: 8px;
  margin: 2px;
  padding: 8px;
}
#entry:selected {
  background-color: #585b70;
  color: #cdd6f4;
}
#entry img {
  margin-right: 8px;
}
EOT

# Create Wlogout layout
WLOGOUT_CONFIG_DIR="$HOME_DIR/.config/wlogout"
sudo -u "$USERNAME" mkdir -p "$WLOGOUT_CONFIG_DIR"
sudo -u "$USERNAME" tee "$WLOGOUT_CONFIG_DIR/layout" > /dev/null <<'EOT'
{
  "label" : "lock",
  "action" : "swaylock -i ~/Pictures/wallpaper.jpg",
  "text" : "Lock",
  "keybind" : "l"
}
{
  "label" : "hibernate",
  "action" : "systemctl hibernate",
  "text" : "Hibernate",
  "keybind" : "h"
}
{
  "label" : "logout",
  "action" : "hyprctl dispatch exit",
  "text" : "Logout",
  "keybind" : "e"
}
{
  "label" : "shutdown",
  "action" : "systemctl poweroff",
  "text" : "Shutdown",
  "keybind" : "s"
}
{
  "label" : "suspend",
  "action" : "systemctl suspend",
  "text" : "Suspend",
  "keybind" : "u"
}
{
  "label" : "reboot",
  "action" : "systemctl reboot",
  "text" : "Reboot",
  "keybind" : "r"
}
EOT

# Create custom scripts and make them executable
BIN_DIR="$HOME_DIR/.local/bin"
sudo -u "$USERNAME" mkdir -p "$BIN_DIR"

sudo -u "$USERNAME" tee "$BIN_DIR/lock-suspend" > /dev/null <<'EOT'
#!/bin/sh
swaylock -i ~/Pictures/wallpaper.jpg &
sleep 1
systemctl suspend
EOT
sudo -u "$USERNAME" chmod +x "$BIN_DIR/lock-suspend"

sudo -u "$USERNAME" tee "$BIN_DIR/launch-apps" > /dev/null <<'EOT'
#!/bin/sh
rofi -show drun \
  -theme ~/.config/rofi/custom.rasi \
  -location 7 \
  -xoffset 10 \
  -yoffset -40
EOT
sudo -u "$USERNAME" chmod +x "$BIN_DIR/launch-apps"

WAYBAR_SCRIPT_DIR="$HOME_DIR/.config/waybar"
sudo -u "$USERNAME" mkdir -p "$WAYBAR_SCRIPT_DIR"
sudo -u "$USERNAME" tee "$WAYBAR_SCRIPT_DIR/mediaplayer.sh" > /dev/null <<'EOT'
#!/bin/sh
player_status=$(playerctl status 2> /dev/null)
if [ "$player_status" = "Playing" ]; then
  echo "$(playerctl metadata artist) - $(playerctl metadata title)"
elif [ "$player_status" = "Paused" ]; then
  echo " $(playerctl metadata artist) - $(playerctl metadata title)"
fi
EOT
sudo -u "$USERNAME" chmod +x "$WAYBAR_SCRIPT_DIR/mediaplayer.sh"

# --- System-level Configurations ---
# Create Hyprland configuration file
HYPR_CONFIG_DIR="$HOME_DIR/.config/hypr"
sudo -u "$USERNAME" mkdir -p "$HYPR_CONFIG_DIR"
sudo -u "$USERNAME" tee "$HYPR_CONFIG_DIR/hyprland.conf" > /dev/null <<'EOT'
# Environment variables (Nvidia variables removed)
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,Adwaita
env = XDG_SESSION_TYPE,wayland
env = ELECTRON_OZONE_PLATFORM_HINT,auto

# Input configuration
input {
  kb_layout = us
  follow_mouse = 1
  touchpad {
    natural_scroll = false
  }
  sensitivity = 0
}

# General configuration
general {
  gaps_in = 5
  gaps_out = 5
  border_size = 3
  col.active_border = rgba(cba6f7ee)
  col.inactive_border = rgba(6c7086dd)
  layout = dwindle
  allow_tearing = false
}

# Decoration
decoration {
  rounding = 10
  blur {
    enabled = true
    size = 3
    passes = 1
  }
}

# Animations
animations {
  enabled = true
  bezier = myBezier, 0.05, 0.9, 0.1, 1.05
  animation = windows, 1, 7, myBezier
  animation = windowsOut, 1, 7, default, popin 80%
  animation = border, 1, 10, default
  animation = borderangle, 1, 8, default
  animation = fade, 1, 7, default
  animation = workspaces, 1, 6, default
}

# Dwindle layout
dwindle {
  pseudotile = true
  preserve_split = true
}

# Gestures
gestures {
  workspace_swipe = true
}

# Miscellaneous
misc {
  force_default_wallpaper = 0
}

# Main modifier key
$mainMod = SUPER

# Key bindings
bind = $mainMod, Q, exec, alacritty
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, nemo
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, ~/.local/bin/launch-apps
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,
bind = $mainMod, L, exec, swaylock -i ~/Pictures/wallpaper.jpg
bind = $mainMod SHIFT, L, exec, ~/.local/bin/lock-suspend
bind = $mainMod, S, exec, grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png
bind = $mainMod, F, exec, grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png
bind = $mainMod, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy

# Focus movement
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Workspace switching
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $main_Mod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9

# Move to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9

# Special workspace (scratchpad)
bind = $mainMod, Z, togglespecialworkspace, magic
bind = $mainMod SHIFT, Z, movetoworkspace, special:magic

# Workspace scrolling
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Media keys
bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMicMute, exec, pamixer --default-source -m
bind = , XF86AudioMute, exec, pamixer -t
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioPause, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous

# Mouse bindings
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, Control_L, movewindow
bindm = $mainMod, mouse:273, resizewindow
bindm = $mainMod, ALT_L, resizewindow

# Startup applications
exec-once = [workspace 1 silent] swaybg -i ~/Pictures/wallpaper.jpg
exec-once = [workspace 1 silent] waybar
exec-once = [workspace 1 silent] mako
exec-once = [workspace 1 silent] nm-applet
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = gnome-keyring-daemon --start --components=secrets,ssh
EOT

# Set up cursor theme configuration via dconf
sudo -u "$USERNAME" dconf write /org/gnome/desktop/interface/cursor-theme "'Adwaita'"
sudo -u "$USERNAME" dconf write /org/gnome/desktop/interface/cursor-size "uint32 24"

# Set up GTK theme configuration
sudo -u "$USERNAME" dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita-dark'"
sudo -u "$USERNAME" dconf write /org/gnome/desktop/interface/icon-theme "'Papirus-Dark'"

# Set up Alacritty configuration
ALACRITTY_CONFIG_DIR="$HOME_DIR/.config/alacritty"
sudo -u "$USERNAME" mkdir -p "$ALACRITTY_CONFIG_DIR"
sudo -u "$USERNAME" tee "$ALACRITTY_CONFIG_DIR/alacritty.yml" > /dev/null <<'EOT'
window:
  opacity: 0.95
  padding:
    x: 10
    y: 10
font:
  normal:
    family: DejaVu Sans Mono
    style: Regular
  size: 12.0
colors:
  primary:
    background: "#1d1f21"
    foreground: "#c5c8c6"
EOT

# Final permissions adjustments
sudo chown -R "$USERNAME":"$USERNAME" "$HOME_DIR/.config" "$HOME_DIR/.local"

echo "Script complete. Reboot your system and you should be greeted by the SDDM login screen."
