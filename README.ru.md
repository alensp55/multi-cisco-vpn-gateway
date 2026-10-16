# Шлюз для нескольких Cisco VPN

[English](README.md)

Дополнительные Cisco-совместимые VPN запускаются в отдельных Ubuntu VM. Windows направляет через каждую VM только
выбранные адреса, не меняя основной VPN на компьютере.

## Требования

- Ubuntu Desktop 24.04+;
- VMware NAT;
- пользователь с `sudo`;
- снимок VM перед установкой.

## Установка

```bash
cp vpn-gateway.conf.example vpn-gateway.conf
nano vpn-gateway.conf
./install.sh --check ./vpn-gateway.conf
sudo ./install.sh ./vpn-gateway.conf
```

Не храните пароль VPN в конфигурации.

```bash
vpn-gateway connect
vpn-gateway status
vpn-gateway plan
vpn-gateway diagnose
```

`plan` показывает выбранный шлюз, интерфейс и маршруты, не изменяя систему. Команда
`vpn-gateway-router plan` аналогично выводит правила nftables без их применения.

## Маршрут Windows

Запустите PowerShell от администратора в каталоге `windows`:

```powershell
.\Add-VpnGatewayRoute.ps1 -TargetIp 192.0.2.40 -VmIp 192.0.2.10
Test-NetConnection 192.0.2.40 -Port 3389
.\Remove-VpnGatewayRoute.ps1 -TargetIp 192.0.2.40 -VmIp 192.0.2.10
```

Замените демонстрационные адреса адресами целевого сервиса и VM.

## Удаление

```bash
sudo ./uninstall.sh
```

Перед использованием прочитайте [SECURITY.md](SECURITY.md) и проверьте правила организации.

## Проверка

```bash
shellcheck bin/vpn-gateway libexec/vpn-gateway-* install.sh uninstall.sh
bats tests/vpn-gateway-lib.bats
```

```powershell
Invoke-Pester -Path tests/VpnGatewayRoute.Tests.ps1
```
