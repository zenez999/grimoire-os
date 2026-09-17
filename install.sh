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
# Farben & Darstellung
# ---------------------------------------------------------------------------

RED='\033[0;31m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

# Eigene, an die Stimmung von Frieren angelehnte Sprüche — bewusst KEINE
# wörtlichen Zitate aus der Serie (Urheberrecht), sondern eigene Sätze im
# selben ruhigen, nachdenklichen Geist.
ZEN_QUOTES=(
    "A long journey is just a lot of short, quiet days."
    "You have more time than you think — spend it slowly."
    "Some things only matter once you look back at them."
    "Not every step needs to be hurried to be meaningful."
    "Memory outlasts everything else you carry."
    "Even a long life is made of small moments."
)

zen_line() {
    echo "${ZEN_QUOTES[$RANDOM % ${#ZEN_QUOTES[@]}]}"
}

HAVE_GUM=false
command -v gum >/dev/null 2>&1 && HAVE_GUM=true

START_TIME=$(date +%s)
TOTAL_STEPS=12
CURRENT_STEP=0

banner() {
    if [[ "$HAVE_GUM" == true ]]; then
        gum style --border double --align center --width 46 --padding "1 2" \
            --border-foreground 111 --foreground 111 --bold \
            "G R I M O I R E   O S" "" "a long journey, taken slowly"
        gum style --align center --width 46 --faint "built on Arch · open source · MIT · fan project"
    else
        echo -e "${CYAN}"
        cat << 'EOF'
        ╔══════════════════════════════════════════════╗
        ║                                              ║
        ║        G R I M O I R E   O S                 ║
        ║        a long journey, taken slowly          ║
        ║                                              ║
        ╚══════════════════════════════════════════════╝
EOF
        echo -e "${RESET}${DIM}      built on Arch · open source · MIT · fan project${RESET}\n"
    fi
    echo ""
}

zen_pause() {
    local quote
    quote="$(zen_line)"
    if [[ "$HAVE_GUM" == true ]]; then
        gum style --faint --italic "   ${quote}"
    else
        echo -e "${DIM}   ${quote}${RESET}"
    fi
    sleep 1
}

step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local prefix="[${CURRENT_STEP}/${TOTAL_STEPS}]"
    if [[ "$HAVE_GUM" == true ]]; then
        gum style --foreground 51 --bold "${prefix} $1"
        gum style --faint "$(printf '─%.0s' $(seq 1 46))"
    else
        echo -e "\n${BOLD}${CYAN}${prefix} $1${RESET}"
    fi
    zen_pause
}

info()  {
    if [[ "$HAVE_GUM" == true ]]; then gum style --faint "    $1"; else echo -e "${DIM}    $1${RESET}"; fi
}
warn()  {
    if [[ "$HAVE_GUM" == true ]]; then gum style --foreground 220 "!!  $1"; else echo -e "${YELLOW}!!  $1${RESET}"; fi
}
ok()    {
    if [[ "$HAVE_GUM" == true ]]; then gum style --foreground 42 "✓   $1"; else echo -e "${GREEN}✓   $1${RESET}"; fi
}
die()   {
    if [[ "$HAVE_GUM" == true ]]; then gum style --foreground 196 --bold "✗ FEHLER: $1"; else echo -e "${RED}✗ FEHLER: $1${RESET}"; fi
    exit 1
}

# Führt einen Befehl aus; zeigt bei vorhandenem gum einen Spinner MIT
# sichtbarer Live-Ausgabe darunter (wichtig für Fehlersuche bei
# pacman/paru — die Ausgabe wird nicht versteckt, nur schöner gerahmt).
run_step() {
    local title="$1"; shift
    if [[ "$HAVE_GUM" == true ]]; then
        gum spin --spinner dot --title "$title" --show-output -- "$@"
    else
        "$@"
    fi
}

# ---------------------------------------------------------------------------
# Vorprüfungen (noch ohne gum, das kommt erst gleich)
# ---------------------------------------------------------------------------

if [[ $EUID -eq 0 ]]; then
    echo "FEHLER: Bitte NICHT als root ausführen. Als normaler User starten (sudo wird intern genutzt)."
    exit 1
fi

command -v sudo >/dev/null 2>&1 || { echo "FEHLER: sudo ist nicht installiert."; exit 1; }

echo "Verbindung wird geprüft..."
ping -c1 -W2 archlinux.org >/dev/null 2>&1 || { echo "FEHLER: Keine Internetverbindung. Erst WLAN/LAN einrichten (nmtui / iwctl), dann erneut starten."; exit 1; }
echo "Verbindung steht."

# gum aus dem offiziellen Repo holen, BEVOR alles andere läuft — damit
# der Rest der Installation die schönere Oberfläche nutzen kann.
if ! command -v gum >/dev/null 2>&1; then
    echo "Richte Oberfläche ein (gum)..."
    sudo pacman -S --needed --noconfirm gum >/dev/null 2>&1 || true
    command -v gum >/dev/null 2>&1 && HAVE_GUM=true
fi

clear
banner

if [[ "$HAVE_GUM" == true ]]; then
    gum confirm "Bereit, GrimoireOS einzurichten?" || { echo "Abgebrochen."; exit 0; }
fi

ok "Verbindung steht, Oberfläche bereit"

# ---------------------------------------------------------------------------
# Optionale Apps auswählen (Kernpakete Helium/kitty/VSCodium/HyprMod sind
# immer dabei — hier geht's nur um die "nice to have"-Auswahl)
# ---------------------------------------------------------------------------
declare -A OPTIONAL_APP_PKGS=(
    ["Discord"]="discord"
    ["Spotify"]="spotify"
    ["Boostnote"]="boostnote-bin"
)
SELECTED_OPTIONAL=()
SELECTED_LABELS=()

if [[ "$HAVE_GUM" == true ]]; then
    echo ""
    mapfile -t SELECTED_LABELS < <(gum choose --no-limit \
        --selected="Discord,Spotify,Boostnote" \
        --header "Optionale Apps (Leertaste zum Wählen, Enter zum Bestätigen):" \
        "Discord" "Spotify" "Boostnote")
else
    SELECTED_LABELS=("Discord" "Spotify" "Boostnote")
fi

for label in "${SELECTED_LABELS[@]}"; do
    SELECTED_OPTIONAL+=("${OPTIONAL_APP_PKGS[$label]}")
done

# ---------------------------------------------------------------------------
# 1. System aktualisieren
# ---------------------------------------------------------------------------
step "System wird aktualisiert"
run_step "Systemaktualisierung läuft..." sudo pacman -Syu --noconfirm

# ---------------------------------------------------------------------------
# 2. Basis-Pakete + AUR-Helper (paru)
#    Bewusst OHNE firefox/foot — GrimoireOS nutzt Helium + kitty
# ---------------------------------------------------------------------------

# multilib aktivieren (32-Bit-Bibliotheken) — wird für Roblox/Sober und
# Minecraft Bedrock (mcpelauncher) gebraucht, ist bei Arch standardmäßig aus
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    step "32-Bit-Unterstützung wird aktiviert (multilib)"
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf >/dev/null
    sudo pacman -Sy --noconfirm
else
    info "multilib bereits aktiv, überspringe"
fi

step "Grundlagen werden gelegt (Basis-Pakete)"
run_step "Basis-Pakete werden installiert..." sudo pacman -S --needed --noconfirm \
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
    lib32-alsa-plugins lib32-libpulse lib32-openal

sudo systemctl enable NetworkManager

AUR_HELPER=""
if command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
    info "AUR-Helfer 'paru' bereits vorhanden, überspringe"
elif command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
    info "AUR-Helfer 'yay' bereits vorhanden, überspringe"
else
    step "AUR-Helfer 'paru' wird gebaut"
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
    (cd "$tmpdir/paru" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
    AUR_HELPER="paru"
fi

# ---------------------------------------------------------------------------
# 3. AUR-Pakete: Caelestia + GrimoireOS-App-Auswahl
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
    helium-browser-bin \
    vscodium-bin \
    hyprmod \
    ttf-udev-gothic \
    "${SELECTED_OPTIONAL[@]}"

sudo systemctl enable power-profiles-daemon

# ---------------------------------------------------------------------------
# 3b. Gaming: Roblox (Sober), Minecraft Bedrock (mcpelauncher)
# ---------------------------------------------------------------------------
step "Gaming wird eingerichtet (Roblox, Minecraft Bedrock)"

# Sober (Roblox) wird offiziell nur als Flatpak vertrieben — zuverlässiger
# als der AUR-Weg
if ! flatpak remote-list | grep -q flathub; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi
flatpak install -y flathub org.vinegarhq.Sober || warn "Sober-Installation fehlgeschlagen — manuell nachholen: flatpak install flathub org.vinegarhq.Sober"

# Minecraft Bedrock über mcpelauncher (zieht mcpelauncher-linux automatisch
# als Abhängigkeit mit)
"$AUR_HELPER" -S --needed --noconfirm mcpelauncher-ui || warn "mcpelauncher-Installation fehlgeschlagen — kann manuell mit '$AUR_HELPER -S mcpelauncher-ui' nachgeholt werden"

# AppImageLauncher: aktuell bekanntermaßen instabil auf Arch/AUR (offener
# Upstream-Bug). Nicht-blockierend, damit ein Fehlschlag hier nicht die
# ganze Installation abbricht.
"$AUR_HELPER" -S --needed --noconfirm appimagelauncher-git || warn "AppImageLauncher-Installation fehlgeschlagen (aktuell bekanntes AUR-Problem) — AppImages funktionieren trotzdem per Doppelklick + 'chmod +x', nur ohne Menü-Integration"

# ---------------------------------------------------------------------------
# 4. Caelestia Shell + Dotfiles
# ---------------------------------------------------------------------------
step "Die Shell erwacht (Caelestia wird eingerichtet)"
caelestia install || warn "caelestia install meldete einen Fehler — ggf. manuell mit 'caelestia install' erneut ausführen"

step "Unnötiges wird losgelassen (firefox/foot entfernen, falls mitinstalliert)"
pacman -Qi firefox >/dev/null 2>&1 && sudo pacman -Rns --noconfirm firefox || true
pacman -Qi foot    >/dev/null 2>&1 && sudo pacman -Rns --noconfirm foot    || true

# ---------------------------------------------------------------------------
# 5. Helium + kitty als Standard setzen
# ---------------------------------------------------------------------------
step "Helium und kitty werden zu deinen Standard-Werkzeugen"

CAELESTIA_CFG="$HOME/.config/caelestia"
mkdir -p "$CAELESTIA_CFG"

HYPR_VARS="$CAELESTIA_CFG/hypr-vars.lua"
if [[ -f "$HYPR_VARS" ]]; then
    warn "$HYPR_VARS existiert bereits — bitte manuell prüfen: browser=\"helium\", terminal=\"kitty\""
else
    cat > "$HYPR_VARS" << 'EOF'
return {
    browser  = "helium",
    terminal = "kitty",
}
EOF
    ok "hypr-vars.lua erstellt (browser=helium, terminal=kitty)"
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

# kitty auf UDEV Gothic NF einstellen — Lateinische Zeichen bleiben normal
# lesbar (basiert auf JetBrains Mono), aber alle Kanji/Symbole bekommen
# den japanischen Look (basiert auf BIZ UD Gothic). Inklusive Nerd-Font-
# Icons für die Caelestia-Statusleiste.
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

# GrimoireOS: ruhige, gedämpfte Farbpalette (überzogener Himmel, alte Wälder —
# eigene Zusammenstellung, keine Reproduktion offizieller Serien-Farben)
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
# 5b. Vorgefertigtes fastfetch — passend zur kitty-Farbpalette
# ---------------------------------------------------------------------------
step "System-Info wird eingerichtet (fastfetch)"

FASTFETCH_CFG_DIR="$HOME/.config/fastfetch"
FASTFETCH_CFG="$FASTFETCH_CFG_DIR/config.jsonc"
mkdir -p "$FASTFETCH_CFG_DIR"
if [[ -f "$FASTFETCH_CFG" ]]; then
    warn "$FASTFETCH_CFG existiert bereits — wird nicht überschrieben"
else
    cat > "$FASTFETCH_CFG" << 'EOF'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "type": "auto",
        "color": {
            "1": "cyan",
            "2": "white"
        }
    },
    "display": {
        "separator": "  "
    },
    "modules": [
        "title",
        "separator",
        { "type": "os", "key": "Realm" },
        { "type": "host", "key": "Vessel" },
        { "type": "kernel", "key": "Core" },
        { "type": "uptime", "key": "Time Since Waking" },
        { "type": "packages", "key": "Spells Known" },
        { "type": "shell", "key": "Tongue" },
        { "type": "wm", "key": "Ward" },
        { "type": "terminal", "key": "Sanctum" },
        { "type": "terminalfont", "key": "Script" },
        { "type": "cpu", "key": "Heartbeat" },
        { "type": "gpu", "key": "Sight" },
        { "type": "memory", "key": "Mind" },
        { "type": "swap", "key": "Mana" },
        { "type": "disk", "key": "Vault" },
        "break",
        "colors"
    ]
}
EOF
    ok "fastfetch config.jsonc erstellt"
fi

# ---------------------------------------------------------------------------
# 6. Fish als Standard-Shell
# ---------------------------------------------------------------------------
step "Fish wird dein Zuhause im Terminal"
FISH_PATH=$(command -v fish)
grep -q "$FISH_PATH" /etc/shells || echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
sudo chsh -s "$FISH_PATH" "$USER"

# ---------------------------------------------------------------------------
# 7. SDDM: Japanese-Aesthetic-Theme
# ---------------------------------------------------------------------------
step "Der Eingang wird gestaltet (SDDM Japanese-Aesthetic-Theme)"

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
# 8. Eigenes Wallpaper übernehmen
# ---------------------------------------------------------------------------
step "Ein Blick nach draußen (Wallpaper wird eingerichtet)"

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

INSTALLED_APPS="VSCodium"
for label in "${SELECTED_LABELS[@]}"; do
    INSTALLED_APPS="${INSTALLED_APPS} · ${label}"
done

echo ""
if [[ "$HAVE_GUM" == true ]]; then
    gum style --border double --align center --width 46 --padding "1 2" \
        --border-foreground 42 --foreground 42 --bold \
        "The installation is complete." "" "Dauer: ${ELAPSED_MIN}m ${ELAPSED_SEC}s"
    echo ""
    gum style --border rounded --width 46 --padding "1 2" --border-foreground 111 \
        "Deine GrimoireOS-Ausstattung" \
        "" \
        "Desktop     Hyprland + Caelestia Shell" \
        "Login       SDDM" \
        "Browser     Helium" \
        "Terminal    kitty (vorkonfiguriert)" \
        "Schrift     UDEVGothic NF" \
        "Shell       fish" \
        "System-Info fastfetch (vorkonfiguriert)" \
        "Apps        ${INSTALLED_APPS}" \
        "Extra       HyprMod | Prism Launcher | Sober (Roblox) | MCPE Launcher"
else
    echo -e "${CYAN}"
    cat << EOF
        ╔══════════════════════════════════════════╗
        ║   The installation is complete.          ║
        ║   Dauer: ${ELAPSED_MIN}m ${ELAPSED_SEC}s                          ║
        ╚══════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
    echo -e "${DIM}Desktop:   Hyprland + Caelestia Shell"
    echo -e "Login:     SDDM"
    echo -e "Browser:   Helium"
    echo -e "Terminal:  kitty"
    echo -e "Schrift:   UDEVGothic NF"
    echo -e "Shell:     fish"
    echo -e "Apps:      ${INSTALLED_APPS}"
    echo -e "Extra:     HyprMod | Prism Launcher | Sober (Roblox) | MCPE Launcher${RESET}"
fi

info "Neustart: sudo reboot"
info "Standard-Browser: Helium  |  Standard-Terminal: kitty"
info "Hyprland-Einstellungen anpassen: 'hyprmod' öffnen (grafische Oberfläche, live-Vorschau)"
info "Theme testen ohne Neustart:"
info "  sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sddm-astronaut-theme/"
echo ""
zen_pause
