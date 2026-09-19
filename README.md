# Grimoire OS

*A long journey, taken slowly.*

An Arch-based setup — Hyprland, the Caelestia shell, a small set of
apps — installed with a single command. No installer wizard, no
interactive menus. You run one line, it runs straight through.

## How to use this, step by step

1. **Install plain Arch first.** Boot the official Arch ISO, run
   `archinstall`, pick the **Minimal** profile (no desktop environment —
   Grimoire handles that part). Finish the install, reboot, log in.
2. **Make sure you have an AUR helper** (`paru` or `yay`) — see
   Requirements below if you don't have one yet.
3. **Check your internet connection:** `ping archlinux.org`
4. **Run the one-line install command** (see Installation below).
5. **Wait.** Twenty minutes to an hour depending on your connection. No
   prompts, no questions — it runs top to bottom on its own.
6. **Reboot:** `sudo reboot`
7. You land on the SDDM login screen. Log in, and Hyprland + the
   Caelestia shell start automatically.

## Requirements

- A fresh, minimal Arch install (or any Arch-based distro — see
  "Does this work on any Arch ISO?" below)
- An internet connection
- A normal user with `sudo` (not root)
- **An AUR helper already installed — `paru` or `yay`.** The script does
  NOT install one for you (kept out on purpose, to keep the script
  simple and predictable). If you don't have one yet:

  ```bash
  sudo pacman -S --needed base-devel git
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si
  ```

## Installation

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/zenez999/grimoire-os/main/grimoire-boot.sh)"
```

That one line clones this repo and runs `install.sh` straight through.

Prefer to see what you're running first:

```bash
git clone https://github.com/zenez999/grimoire-os.git
cd grimoire-os
chmod +x install.sh
./install.sh
```

## What exactly is in the script

The script runs these stages, in order, with no interaction needed:

1. **Connection check** — makes sure archlinux.org is reachable before
   doing anything
2. **System update** — `pacman -Syu`
3. **multilib enabled** — 32-bit libraries, needed for Roblox/Minecraft
   Bedrock audio
4. **Base packages** — Hyprland, kitty, fish, btop, fastfetch, SDDM,
   PipeWire, fonts, Prism Launcher, Java, and the 32-bit audio libs
5. **AUR helper check** — confirms `paru`/`yay` exists, stops with a
   clear message if not (see Requirements)
6. **AUR packages** — Caelestia CLI, Quickshell, Zen Browser, VSCodium,
   HyprMod, and your gaming extras (see below)
7. **Gaming setup** — Sober (Roblox) via Flatpak, mcpelauncher
   (Minecraft Bedrock), AppImageLauncher
8. **Caelestia shell install** — runs `caelestia install`, then removes
   Firefox/foot if it pulled them in as defaults
9. **Zen Browser + kitty set as defaults** — writes
   `~/.config/caelestia/hypr-vars.lua` and `shell.json`, plus a kitty
   config with a font and color palette
10. **fastfetch config** — a pre-made `config.jsonc` with its own
    vocabulary (swap becomes "Mana," uptime becomes "Time Since Waking")
11. **fish set as default shell**
12. **SDDM theme** — Pixel Sakura background
13. **Wallpaper** — copies anything in a local `wallpapers/` folder and
    activates `default.jpg`/`.png` if present

## What's included

**Desktop**
- Hyprland (Wayland compositor)
- Caelestia shell (Quickshell-based)
- SDDM, Pixel Sakura theme
- [HyprMod](https://github.com/BlueManCZ/hyprmod) — graphical Hyprland
  settings, so you don't have to hand-edit the config for every tweak

**Apps**
- [Zen Browser](https://zen-browser.app/) — Firefox-based, calm UI,
  vertical tabs, workspaces
- kitty — terminal, pre-configured with [UDEV Gothic](https://github.com/yuru7/udev-gothic)
  and a muted color palette
- VSCodium, Discord, Spotify, Boostnote

**Gaming**
- [Prism Launcher](https://prismlauncher.org/) — Minecraft: Java Edition
  (Java included)
- [Sober](https://sober.vinegarhq.org/) — Roblox, installed via Flatpak
- [mcpelauncher](https://minecraft-linux.github.io/) — Minecraft:
  Bedrock Edition
- AppImageLauncher — run `.AppImage` files by double-click. **Known
  issue:** currently has build problems on the AUR upstream; the
  installer tries anyway and won't fail the rest of setup if it
  doesn't build. AppImages still run fine manually
  (`chmod +x file.AppImage && ./file.AppImage`) without it.

**Terminal**
- fish as the default shell
- fastfetch, pre-configured with its own vocabulary

### Bring your own wallpaper

Drop images into a `wallpapers/` folder at the root of your own local
copy. Name your favorite `default.jpg` (or `.png`) and it'll be set
active automatically on first boot. Keep personally-sourced or
copyrighted images local rather than committing them to a public fork
of this repo.

## Does this work on any Arch ISO?

**Yes, on any Arch-based distro that uses `pacman`** — Arch itself,
Manjaro, EndeavourOS, Garuda, ArcoLinux, and similar. The script
detects whichever AUR helper you already have (`paru` or `yay`) instead
of assuming one specific setup.

**No, not on non-Arch distros** — Debian, Ubuntu, Fedora, openSUSE, and
NixOS use entirely different package managers (`apt`, `dnf`, `zypper`,
`nix`). The script would fail immediately on the first `pacman` command
on any of those.

One honest caveat: Arch derivatives like Manjaro sometimes lag slightly
behind Arch's own repos, which could occasionally cause a version
mismatch. This hasn't been tested across every derivative — if you hit
something distro-specific, it's worth checking that first.

## After it's running

- Change wallpaper: `caelestia wallpaper -f <path>`
- Hyprland tweaks: `~/.config/caelestia/hypr-vars.lua`
- Shell config: `~/.config/caelestia/shell.json`
- kitty font/colors: `~/.config/kitty/kitty.conf`
- fastfetch wording: `~/.config/fastfetch/config.jsonc`
- SDDM theme variant: edit `ConfigFile=` in
  `/usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop`

## License

MIT. Fork it, strip it down, make it yours.

---

*A long journey is just a lot of short, quiet days.*
