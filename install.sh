#!/usr/bin/env bash
#
#   G R I M O I R E   O S
#   An Arch-based system built around stillness, memory, and quiet time.
#   https://github.com/zenez999/grimoire-os
#
#   MIT Licensed — free and open source.
#   NICHT als root ausführen. sudo wird intern genutzt.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Einfache Text-Ausgabe, keine externen TUI-Tools
# ---------------------------------------------------------------------------

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

TOTAL_STEPS=13
CURRENT_STEP=0

step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "\n${BOLD}${CYAN}==> [${CURRENT_STEP}/${TOTAL_STEPS}] $1${RESET}"
}
info() { echo -e "${DIM}    $1${RESET}"; }
warn() { echo -e "${YELLOW}!!  $1${RESET}"; }
ok()   { echo -e "${GREEN}✓   $1${RESET}"; }
die()  { echo -e "${RED}✗ FEHLER: $1${RESET}"; exit 1; }

echo -e "${CYAN}"
cat << 'EOF'
======================================
        GRIMOIRE OS
        a long journey, taken slowly
======================================
EOF
echo -e "${RESET}"

START_TIME=$(date +%s)

# ---------------------------------------------------------------------------
# Vorprüfungen
# ---------------------------------------------------------------------------

if [[ $EUID -eq 0 ]]; then
    die "Bitte NICHT als root ausführen. Als normaler User starten (sudo wird intern genutzt)."
fi

command -v sudo >/dev/null 2>&1 || die "sudo ist nicht installiert."

step "Verbindung wird geprüft"
ping -c1 -W2 archlinux.org >/dev/null 2>&1 || die "Keine Internetverbindung. Erst WLAN/LAN einrichten (nmtui / iwctl), dann erneut starten."
ok "Verbindung steht"

# Alle "nice to have"-Apps sind standardmäßig dabei — keine interaktive
# Auswahl mehr, läuft einfach komplett durch
SELECTED_OPTIONAL=(discord spotify boostnote-bin)

# ---------------------------------------------------------------------------
# 1. System aktualisieren
# ---------------------------------------------------------------------------
step "System wird aktualisiert"
sudo pacman -Syu --noconfirm

# ---------------------------------------------------------------------------
# 2. multilib aktivieren (32-Bit-Bibliotheken für Roblox/Bedrock)
# ---------------------------------------------------------------------------
step "32-Bit-Unterstützung wird aktiviert (multilib)"
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf >/dev/null
    sudo pacman -Sy --noconfirm
else
    info "multilib bereits aktiv, überspringe"
fi

# ---------------------------------------------------------------------------
# 3. Basis-Pakete
#    Bewusst OHNE firefox/foot — GrimoireOS nutzt Zen Browser + kitty
# ---------------------------------------------------------------------------
step "Grundlagen werden gelegt (Basis-Pakete)"
sudo pacman -S --needed --noconfirm \
    base-devel git curl wget unzip \
    networkmanager \
    hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
    qt6-base qt6-declarative qt6-svg qt6-imageformats qt6-multimedia-ffmpeg qt6-virtualkeyboard qt6-shadertools qt6-5compat \
    fish kitty btop fastfetch \
    sddm \
    pipewire pipewire-pulse pipewire-alsa wireplumber \
    brightnessctl playerctl \
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk noto-fonts-emoji \
    gnome-desktop-4 \
    thunar \
    cmake ninja \
    flatpak \
    prismlauncher jdk-openjdk \
    starship \
    lib32-alsa-plugins lib32-libpulse lib32-openal

sudo systemctl enable NetworkManager

# ---------------------------------------------------------------------------
# 4. AUR-Helfer prüfen (wird NICHT automatisch gebaut — siehe README)
# ---------------------------------------------------------------------------
step "AUR-Helfer wird geprüft"
if command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
elif command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
else
    die "Kein AUR-Helfer gefunden. Bitte zuerst 'paru' oder 'yay' installieren (siehe README), dann dieses Skript erneut starten."
fi
ok "AUR-Helfer gefunden: $AUR_HELPER"

# ---------------------------------------------------------------------------
# 5. AUR-Pakete: Caelestia + App-Auswahl
# ---------------------------------------------------------------------------
step "Die Werkzeuge werden versammelt (AUR-Pakete)"
"$AUR_HELPER" -S --needed --noconfirm \
    caelestia-cli \
    quickshell-git \
    ddcutil \
    libcava \
    aubio \
    libqalculate \
    power-profiles-daemon \
    ttf-material-symbols-variable \
    ttf-rubik-vf \
    qt6-m3shapes-git \
    swappy \
    zen-browser-bin \
    vscodium-bin \
    hyprmod \
    ttf-udev-gothic \
    "${SELECTED_OPTIONAL[@]}"

sudo systemctl enable power-profiles-daemon

# ---------------------------------------------------------------------------
# 6. Gaming: Roblox (Sober), Minecraft Bedrock (mcpelauncher)
# ---------------------------------------------------------------------------
step "Gaming wird eingerichtet (Roblox, Minecraft Bedrock)"

if ! flatpak remote-list 2>/dev/null | grep -q flathub; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi
flatpak install -y flathub org.vinegarhq.Sober || warn "Sober-Installation fehlgeschlagen — manuell nachholen: flatpak install flathub org.vinegarhq.Sober"

"$AUR_HELPER" -S --needed --noconfirm mcpelauncher-ui || warn "mcpelauncher-Installation fehlgeschlagen — kann manuell mit '$AUR_HELPER -S mcpelauncher-ui' nachgeholt werden"

"$AUR_HELPER" -S --needed --noconfirm appimagelauncher-git || warn "AppImageLauncher-Installation fehlgeschlagen (bekanntes AUR-Problem) — AppImages funktionieren trotzdem per 'chmod +x' + Doppelklick"

# ---------------------------------------------------------------------------
# 7. Caelestia Shell + Dotfiles
# ---------------------------------------------------------------------------
step "Die Shell wird eingerichtet (Caelestia)"
caelestia install || warn "caelestia install meldete einen Fehler — ggf. manuell mit 'caelestia install' erneut ausführen"

pacman -Qi firefox >/dev/null 2>&1 && sudo pacman -Rns --noconfirm firefox || true
pacman -Qi foot    >/dev/null 2>&1 && sudo pacman -Rns --noconfirm foot    || true

# ---------------------------------------------------------------------------
# 8. Zen Browser + kitty als Standard setzen
# ---------------------------------------------------------------------------
step "Zen Browser und kitty werden zu deinen Standard-Werkzeugen"

CAELESTIA_CFG="$HOME/.config/caelestia"
mkdir -p "$CAELESTIA_CFG"

HYPR_VARS="$CAELESTIA_CFG/hypr-vars.lua"
if [[ -f "$HYPR_VARS" ]]; then
    warn "$HYPR_VARS existiert bereits — bitte manuell prüfen: browser=\"zen-browser\", terminal=\"kitty\""
else
    cat > "$HYPR_VARS" << 'EOF'
return {
    browser  = "zen-browser",
    terminal = "kitty",
}
EOF
    ok "hypr-vars.lua erstellt (browser=zen-browser, terminal=kitty)"
fi

SHELL_JSON="$CAELESTIA_CFG/shell.json"
if [[ -f "$SHELL_JSON" ]]; then
    warn "$SHELL_JSON existiert bereits — bitte 'general.apps.terminal' manuell auf [\"kitty\"] setzen"
else
    cat > "$SHELL_JSON" << 'EOF'
{
    "general": {
        "apps": {
            "terminal": ["kitty"],
            "explorer": ["thunar"]
        }
    }
}
EOF
    ok "shell.json erstellt (terminal=kitty)"
fi

KITTY_CFG_DIR="$HOME/.config/kitty"
KITTY_CFG="$KITTY_CFG_DIR/kitty.conf"
mkdir -p "$KITTY_CFG_DIR"
if [[ -f "$KITTY_CFG" ]] && grep -q "^font_family" "$KITTY_CFG" 2>/dev/null; then
    warn "$KITTY_CFG hat bereits eine font_family — bitte manuell auf 'UDEVGothic NF' prüfen"
else
    cat >> "$KITTY_CFG" << 'EOF'

# GrimoireOS: Schrift mit ruhigem, gedämpftem Look (Latein bleibt lesbar)
font_family      UDEVGothic NF
bold_font        UDEVGothic NF Bold
italic_font      UDEVGothic NF Italic
bold_italic_font UDEVGothic NF Bold Italic
font_size        11.0

# GrimoireOS: ruhige, gedämpfte Farbpalette (eigene Zusammenstellung)
background            #1e2124
foreground            #d8dee9
selection_background  #3b4252
selection_foreground  #eceff4
cursor                #88c0b0
url_color             #88c0b0

color0  #2e3440
color8  #4c566a
color1  #a97fa5
color9  #b48ead
color2  #8fae9c
color10 #a3c9b5
color3  #d0b47a
color11 #e0c992
color4  #7d9fc4
color12 #9dbde0
color5  #a58bc4
color13 #b9a3d6
color6  #7fb3b3
color14 #9fd0d0
color7  #d8dee9
color15 #eceff4
EOF
    ok "kitty.conf erstellt (Schrift + ruhige Farbpalette)"
fi

# ---------------------------------------------------------------------------
# 9. Vorgefertigtes fastfetch
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# 9. Vorgefertigtes fastfetch (überschreibt IMMER — auch falls Caelestia
#    beim Setup schon eine eigene Default-Config angelegt hat)
# ---------------------------------------------------------------------------
step "System-Info wird eingerichtet (fastfetch)"

FASTFETCH_CFG_DIR="$HOME/.config/fastfetch"
FASTFETCH_CFG="$FASTFETCH_CFG_DIR/config.jsonc"
mkdir -p "$FASTFETCH_CFG_DIR"
[[ -f "$FASTFETCH_CFG" ]] && info "Bestehende fastfetch-Config wird ersetzt"

# Bewusst OHNE 'EOF' in Anführungszeichen, damit $HOME unten aufgelöst wird
cat > "$FASTFETCH_CFG" << EOF
{
    "\$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "type": "kitty",
        "source": "$HOME/Downloads/frieren.png",
        "width": 26,
        "height": 13,
        "padding": {
            "top": 1,
            "left": 2,
            "right": 3
        }
    },
    "display": {
        "separator": "  ❄  ",
        "color": {
            "keys": "38;2;137;180;250",
            "title": "38;2;180;190;254"
        }
    },
    "modules": [
        {
            "type": "custom",
            "format": "┌─────────── 󰋜 GRIMOIRE-OS ───────────┐"
        },
        {
            "type": "title",
            "key": "  󰧱 Magier",
            "format": "{1}@{2}"
        },
        {
            "type": "os",
            "key": "  󰣇 Reich",
            "format": "{2}"
        },
        {
            "type": "kernel",
            "key": "  󰅐 Magiekern",
            "format": "{2}"
        },
        {
            "type": "uptime",
            "key": "  󱎫 Meditationszeit"
        },
        {
            "type": "packages",
            "key": "  󰏖 Zaubersprüche"
        },
        {
            "type": "shell",
            "key": "  󰞷 Beschwörung"
        },
        {
            "type": "custom",
            "format": "├─────────── 󰓅 MANA & RESSOURCEN ───────────┤"
        },
        {
            "type": "memory",
            "key": "  󰍛 Aktives Mana"
        },
        {
            "type": "swap",
            "key": "  󰓡 Reserviertes Mana"
        },
        {
            "type": "disk",
            "key": "  󰋊 Zauberbuch"
        },
        {
            "type": "custom",
            "format": "└─────────────────────────────────────────┘"
        },
        "break",
        {
            "type": "colors",
            "symbol": "circle"
        }
    ]
}
EOF
ok "fastfetch config.jsonc erstellt"

# ---------------------------------------------------------------------------
# 10. Fish als Standard-Shell
# ---------------------------------------------------------------------------
step "Fish wird dein Zuhause im Terminal"
FISH_PATH=$(command -v fish)
grep -q "$FISH_PATH" /etc/shells || echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
sudo chsh -s "$FISH_PATH" "$USER"

# ---------------------------------------------------------------------------
# 10b. Starship-Prompt mit eigener Grimoire-Config
# ---------------------------------------------------------------------------
step "Der Prompt wird verzaubert (Starship)"

FISH_CFG_DIR="$HOME/.config/fish"
FISH_CFG="$FISH_CFG_DIR/config.fish"
mkdir -p "$FISH_CFG_DIR"
if ! grep -q "starship init fish" "$FISH_CFG" 2>/dev/null; then
    echo -e "\nstarship init fish | source" >> "$FISH_CFG"
    ok "Starship in fish eingehängt"
else
    info "Starship bereits in fish eingehängt, überspringe"
fi

STARSHIP_CFG="$HOME/.config/starship.toml"
[[ -f "$STARSHIP_CFG" ]] && info "Bestehende starship.toml wird ersetzt"

cat > "$STARSHIP_CFG" << 'EOF'
# GrimoireOS — ruhiger, gedämpfter Prompt im selben Farbton wie kitty/fastfetch

format = """
[┌───](fg:#4c566a)$os$username$hostname$directory$git_branch$git_status
[└─](fg:#4c566a)$character
"""

[os]
disabled = false
style = "fg:#88c0b0"
format = "[$symbol]($style)"

[os.symbols]
Arch = "󰣇 "

[username]
style_user = "fg:#d8dee9 bold"
format = "[$user]($style)@"
show_always = false

[hostname]
style = "fg:#9dbde0"
format = "[$hostname]($style) "

[directory]
style = "fg:#7d9fc4 bold"
format = "[ $path]($style) "
truncation_length = 3
truncate_to_repo = true

[git_branch]
symbol = " "
style = "fg:#a58bc4"
format = "[$symbol$branch]($style) "

[git_status]
style = "fg:#d0b47a"
format = "([$all_status$ahead_behind]($style)) "

[character]
success_symbol = "[❯](bold fg:#8fae9c)"
error_symbol = "[❯](bold fg:#a97fa5)"

[cmd_duration]
format = "took [$duration](fg:#e0c992) "
min_time = 2000

[package]
disabled = true
EOF
ok "starship.toml erstellt (Grimoire-Farbpalette)"

# ---------------------------------------------------------------------------
# 11. SDDM: Pixel-Sakura-Theme
# ---------------------------------------------------------------------------
step "Der Eingang wird gestaltet (SDDM Pixel-Sakura-Theme)"

if [[ ! -d /usr/share/sddm/themes/sddm-astronaut-theme ]]; then
    sudo git clone -b master --depth 1 \
        https://github.com/keyitdev/sddm-astronaut-theme.git \
        /usr/share/sddm/themes/sddm-astronaut-theme
fi

sudo cp -r /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/ 2>/dev/null || true

echo "[Theme]
Current=sddm-astronaut-theme" | sudo tee /etc/sddm.conf >/dev/null

sudo mkdir -p /etc/sddm.conf.d
echo "[General]
InputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/virtualkbd.conf >/dev/null

THEME_META="/usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop"
if [[ -f "$THEME_META" ]]; then
    sudo sed -i 's|^ConfigFile=.*|ConfigFile=Themes/pixel_sakura.conf|' "$THEME_META"
else
    warn "metadata.desktop nicht gefunden — Theme-Variante manuell auf 'Themes/pixel_sakura.conf' setzen"
fi

sudo systemctl enable sddm

# ---------------------------------------------------------------------------
# 12. Eigenes Wallpaper übernehmen
# ---------------------------------------------------------------------------
step "Wallpaper wird eingerichtet"

WALLPAPER_SRC="$SCRIPT_DIR/wallpapers"
WALLPAPER_DEST="$HOME/Pictures/Wallpapers"

if [[ -d "$WALLPAPER_SRC" ]] && [[ -n "$(ls -A "$WALLPAPER_SRC" 2>/dev/null)" ]]; then
    mkdir -p "$WALLPAPER_DEST"
    cp -r "$WALLPAPER_SRC"/. "$WALLPAPER_DEST"/
    ok "Wallpaper nach $WALLPAPER_DEST kopiert"

    DEFAULT_WALLPAPER=$(find "$WALLPAPER_DEST" -maxdepth 1 -iname "default.*" \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | head -n1)
    [[ -z "$DEFAULT_WALLPAPER" ]] && DEFAULT_WALLPAPER=$(find "$WALLPAPER_DEST" -maxdepth 1 \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | sort | head -n1)

    if [[ -n "$DEFAULT_WALLPAPER" ]]; then
        caelestia wallpaper -f "$DEFAULT_WALLPAPER" 2>/dev/null || info "Wallpaper wird beim ersten Login automatisch aktiv"
    fi
else
    info "Kein 'wallpapers/'-Ordner gefunden — Standard-Wallpaper bleibt aktiv"
fi

# ---------------------------------------------------------------------------
# Fertig
# ---------------------------------------------------------------------------
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
ELAPSED_MIN=$((ELAPSED / 60))
ELAPSED_SEC=$((ELAPSED % 60))

echo -e "\n${CYAN}"
cat << EOF
======================================
  Die Installation ist vollendet.
  Dauer: ${ELAPSED_MIN}m ${ELAPSED_SEC}s
======================================
EOF
echo -e "${RESET}"
echo -e "${DIM}Desktop:   Hyprland + Caelestia Shell"
echo -e "Login:     SDDM (Pixel Sakura)"
echo -e "Browser:   Zen Browser"
echo -e "Terminal:  kitty (vorkonfiguriert)"
echo -e "Schrift:   UDEVGothic NF"
echo -e "Shell:     fish + Starship-Prompt"
echo -e "Apps:      VSCodium · Discord · Spotify · Boostnote"
echo -e "Gaming:    Prism Launcher · Sober (Roblox) · MCPE Launcher"
echo -e "Extra:     HyprMod (grafische Hyprland-Settings)${RESET}"
echo ""
info "Neustart: sudo reboot"
info "Theme testen ohne Neustart:"
info "  sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sddm-astronaut-theme/"
