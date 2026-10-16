[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({
        $address = $_ -as [ipaddress]
        $address -and $address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork
    })]
    [string]$TargetIp,

    [Parameter(Mandatory)]
    [ValidateScript({
        $address = $_ -as [ipaddress]
        $address -and $address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork
    })]
    [string]$VmIp,

    [string]$InterfaceAlias = "VMware Network Adapter VMnet8"
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "VpnGatewayRoute.psm1") -Force
$prefix = ConvertTo-VpnHostPrefix -Address $TargetIp
$interfaces = @(Get-NetIPInterface -AddressFamily IPv4 -InterfaceAlias $InterfaceAlias)
if ($interfaces.Count -ne 1) {
    throw "Expected one IPv4 interface named '$InterfaceAlias', found $($interfaces.Count)."
}
$interface = $interfaces[0]
$active = @(Get-NetRoute -AddressFamily IPv4 -DestinationPrefix $prefix -PolicyStore ActiveStore `
    -ErrorAction SilentlyContinue)
$persistent = @(Get-NetRoute -AddressFamily IPv4 -DestinationPrefix $prefix -PolicyStore PersistentStore `
    -ErrorAction SilentlyContinue)
$routes = Get-MatchingVpnRoutes -Routes @($persistent + $active) -NextHop $VmIp `
    -InterfaceIndex $interface.InterfaceIndex

if ($routes.Count -eq 0) {
    Write-Host "Matching route does not exist: $prefix via $VmIp on $InterfaceAlias"
    exit 0
}

$routes | Remove-NetRoute -Confirm:$false
$activeRemaining = @(Get-NetRoute -AddressFamily IPv4 -DestinationPrefix $prefix -PolicyStore ActiveStore `
    -ErrorAction SilentlyContinue)
$persistentRemaining = @(Get-NetRoute -AddressFamily IPv4 -DestinationPrefix $prefix -PolicyStore PersistentStore `
    -ErrorAction SilentlyContinue)
$remaining = Get-MatchingVpnRoutes -Routes @($activeRemaining + $persistentRemaining) -NextHop $VmIp `
    -InterfaceIndex $interface.InterfaceIndex
if ($remaining) {
    throw "The route still exists in ActiveStore or PersistentStore."
}
Write-Host "Removed route: $prefix via $VmIp on $InterfaceAlias"
