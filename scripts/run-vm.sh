#!/usr/bin/env bash
# Boot a KozaOS ISO in QEMU.
# Usage: ./scripts/run-vm.sh <iso> [--bios|--uefi] [--old-cpu] [--ram MB]
set -euo pipefail

usage() { echo "usage: $0 <iso> [--bios|--uefi] [--old-cpu] [--ram MB]" >&2; exit 1; }
[[ $# -ge 1 ]] || usage
iso="$1"; shift
[[ -f "$iso" ]] || { echo "no such file: $iso" >&2; exit 1; }

mode=uefi ram=4096 old_cpu=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --bios) mode=bios ;;
        --uefi) mode=uefi ;;
        --old-cpu) old_cpu=1 ;;
        --ram) [[ "${2:-}" =~ ^[0-9]+$ ]] || usage; ram="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

args=(-m "$ram" -smp 2 -cdrom "$iso" -boot d -vga virtio -nic user,model=virtio-net-pci)

if [[ $old_cpu -eq 1 ]]; then
    # No KVM: under KVM the host CPU runs SSE4.2/POPCNT anyway, so only emulation
    # turns them into the "illegal instruction" a real Core 2 Duo would hit.
    args+=(-cpu core2duo)
else
    args+=(-enable-kvm -cpu host)
fi

if [[ $mode == uefi ]]; then
    ovmf=/usr/share/edk2/x64
    vars="$(mktemp --suffix=.fd)"
    trap 'rm -f "$vars"' EXIT
    cp "$ovmf/OVMF_VARS.4m.fd" "$vars"
    args+=(-drive "if=pflash,format=raw,readonly=on,file=$ovmf/OVMF_CODE.4m.fd"
           -drive "if=pflash,format=raw,file=$vars")
fi

qemu-system-x86_64 "${args[@]}"
