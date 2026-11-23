#!/usr/bin/env bash
# Build a KozaOS ISO: merge archiso/common with a flavor, then run mkarchiso.
# Usage: sudo ./scripts/build-iso.sh xfce|kde|all
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

usage() { echo "usage: sudo $0 xfce|kde|all" >&2; exit 1; }
[[ $# -eq 1 ]] || usage
case "$1" in
    xfce|kde) flavors=("$1") ;;
    all) flavors=(xfce kde) ;;
    *) usage ;;
esac
[[ $EUID -eq 0 ]] || { echo "mkarchiso needs root, run with sudo" >&2; exit 1; }

# Own package cache, so the build machine's cache (e.g. CachyOS v3 builds) never ends up in the ISO.
cache="$root/cache/pkg"
mkdir -p "$cache" "$root/out"

for flavor in "${flavors[@]}"; do
    work="$root/work/$flavor"
    profile="$work/profile"
    rm -rf "$work"
    mkdir -p "$work"

    cp -a "$root/archiso/common" "$profile"
    rm -f "$profile/.gitkeep"
    if [[ -d "$root/archiso/$flavor/airootfs" ]]; then
        cp -a "$root/archiso/$flavor/airootfs/." "$profile/airootfs/"
    fi
    # Flavor packages are optional; duplicates are dropped, first occurrence wins.
    flavor_pkgs="$root/archiso/$flavor/packages.x86_64"
    [[ -f "$flavor_pkgs" ]] || flavor_pkgs=/dev/null
    awk '!seen[$0]++' "$root/archiso/common/packages.x86_64" "$flavor_pkgs" > "$profile/packages.x86_64"

    sed -i "s/^iso_name=.*/iso_name=\"kozaos-$flavor\"/" "$profile/profiledef.sh"
    sed -i "/^\[options\]/a CacheDir = $cache" "$profile/pacman.conf"

    mkarchiso -v -w "$work/work" -o "$root/out" "$profile"
done

# Let the invoking user read and delete the outputs.
[[ -n "${SUDO_UID:-}" ]] && chown -R "$SUDO_UID:$SUDO_GID" "$root/out" "$root/cache"
ls -lh "$root"/out/*.iso
