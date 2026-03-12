# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

```bash
# Apply configuration changes
sudo nixos-rebuild switch --upgrade --flake /etc/nixos/#nixos --option access-tokens "github.com=$GITHUB_TOKEN" --show-trace

# Apply with verbose nix output
sudo nixos-rebuild switch --upgrade --flake /etc/nixos/#nixos --option access-tokens "github.com=$GITHUB_TOKEN" --show-trace |& nom

# Update flake inputs
nix flake update

# Update a single input
nix flake update nixpkgs
```

## Architecture

This is a NixOS system configuration using **flakes** with **home-manager** integrated as a NixOS module.

- `flake.nix` — entry point; defines all external inputs and wires them into a single `nixosSystem`
- `configuration.nix` — system-level config: boot, hardware, networking, services, fonts, system packages, environment variables
- `home.nix` — user-level config via home-manager for user `ayamir`: user packages, shell programs (starship), XDG desktop entries
- `hardware-configuration.nix` — auto-generated hardware scan, not manually edited
- `packages/` — custom NixOS module overlays (e.g., `wallpaper-engine-kde-plugin.nix`)

## Key Details

- **nixpkgs channel**: `nixos-unstable`
- **home-manager release**: `release-24.11` (follows nixpkgs)
- **User**: `ayamir`, shell is `fish`, NOPASSWD sudo
- **Desktop**: KDE Plasma 6 + Wayland (SDDM)
- **GPU**: AMD (ROCm/amdvlk), `amdgpu` kernel module
- **Substituters**: sjtu mirror and garnix cache configured for faster builds in China

## Where to Add Packages

- **System-wide tools** (available to all users, including root): `environment.systemPackages` in `configuration.nix`
- **User applications** (GUI apps, user-specific tools): `home.packages` in `home.nix`

## Notable Flake Inputs

- `nur` — NixOS User Repository (used for `nur.repos.instantos.spotify-adblock` in home.nix)
- `claude-code` — overlay from `sadjow/claude-code-nix`
- `zen-browser`, `browser-previews` — third-party browser flakes
- `kwin-effects-forceblur` — KWin blur effect plugin
