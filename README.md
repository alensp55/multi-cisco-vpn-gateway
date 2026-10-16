# Multi Cisco VPN Gateway

[Русский](README.ru.md)

Runs additional Cisco-compatible VPN connections in isolated Ubuntu VMs. Windows routes only selected addresses
through each VM, so the host VPN remains unchanged.

## Requirements

- Ubuntu Desktop 24.04+ VM;
- VMware NAT adapter;
- existing user with sudo access;
- VM snapshot before installation.

## Install

```bash
cp vpn-gateway.conf.example vpn-gateway.conf
nano vpn-gateway.conf
./install.sh --check ./vpn-gateway.conf
sudo ./install.sh ./vpn-gateway.conf
```

Do not store the VPN password in the configuration.

```bash
vpn-gateway connect
vpn-gateway status
vpn-gateway plan
vpn-gateway diagnose
```

`plan` prints the selected gateway, tunnel and routes without changing the system. The router has a similar
`vpn-gateway-router plan` command that renders the nftables rules without applying them.

## Windows route

Run elevated PowerShell in `windows`:

```powershell
.\Add-VpnGatewayRoute.ps1 -TargetIp 192.0.2.40 -VmIp 192.0.2.10
Test-NetConnection 192.0.2.40 -Port 3389
.\Remove-VpnGatewayRoute.ps1 -TargetIp 192.0.2.40 -VmIp 192.0.2.10
```

Replace the documentation addresses with your target and VM addresses.

## Remove

```bash
sudo ./uninstall.sh
```

See [SECURITY.md](SECURITY.md). Use a dedicated VM and confirm that local VPN routing is allowed by policy.

## Test

```bash
shellcheck bin/vpn-gateway libexec/vpn-gateway-* install.sh uninstall.sh
bats tests/vpn-gateway-lib.bats
```

```powershell
Invoke-Pester -Path tests/VpnGatewayRoute.Tests.ps1
```
