#!/usr/bin/env bash
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run with sudo: sudo ./uninstall.sh" >&2; exit 1; }

appliance_user=""
if [[ -r /etc/vpn-gateway.conf ]]; then
    # shellcheck disable=SC1091
    source /etc/vpn-gateway.conf
    appliance_user=${APPLIANCE_USER:-}
fi

systemctl disable --now vpn-gateway-router.service 2>/dev/null || true
/usr/sbin/nft delete table inet vpn_gateway 2>/dev/null || true

rm -f /etc/systemd/system/vpn-gateway-router.service
rm -f /etc/sysctl.d/90-vpn-gateway.conf
rm -f /etc/sudoers.d/90-vpn-gateway
rm -f /etc/vpn-gateway.conf
rm -f /usr/local/bin/vpn-gateway
rm -f /usr/local/libexec/vpn-gateway-router
rm -f /usr/local/libexec/vpn-gateway-lib

state_dir=/var/lib/vpn-gateway
if [[ -e $state_dir/resolv.conf.original || -L $state_dir/resolv.conf.original ]]; then
    rm -f /etc/resolv.conf
    mv "$state_dir/resolv.conf.original" /etc/resolv.conf
fi
rmdir "$state_dir" 2>/dev/null || true

if [[ -n $appliance_user ]]; then
    home=$(getent passwd "$appliance_user" | cut -d: -f6)
    rm -f "$home/Desktop/VPN Gateway.desktop"
fi

systemctl daemon-reload
sysctl --system >/dev/null
echo "vpn-gateway removed. NetworkManager profile changes were left in place for safety."
