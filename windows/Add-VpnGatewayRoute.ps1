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
$activeExisting = @(Get-NetRoute -AddressFamily IPv4 -DestinationPrefix $prefix -PolicyStore ActiveStore `
    -ErrorAction SilentlyContinue)
$persistentExisting = @(Get-NetRoute -AddressFamily IPv4 -DestinationPrefix $prefix -PolicyStore PersistentStore `
    -ErrorAction SilentlyContinue)
$decision = Get-VpnRouteDecision -ActiveRoutes $activeExisting -PersistentRoutes $persistentExisting `
    -NextHop $VmIp -InterfaceIndex $interface.InterfaceIndex
switch ($decision) {
    "Conflict" { throw "A different route already exists for $prefix." }
    "Partial" { throw "Route exists in only one policy store. Remove it and add it again." }
    "Exists" { Write-Host "Route already exists: $prefix via $VmIp"; exit 0 }
}

New-NetRoute -DestinationPrefix $prefix -InterfaceIndex $interface.InterfaceIndex -NextHop $VmIp | Out-Null
$active = @(Get-NetRoute -AddressFamily IPv4 -DestinationPrefix $prefix -PolicyStore ActiveStore)
$persistent = @(Get-NetRoute -AddressFamily IPv4 -DestinationPrefix $prefix -PolicyStore PersistentStore)
$activeMatch = $active | Where-Object { $_.NextHop -eq $VmIp -and $_.InterfaceIndex -eq $interface.InterfaceIndex }
$persistentMatch = $persistent | Where-Object {
    $_.NextHop -eq $VmIp -and $_.InterfaceIndex -eq $interface.InterfaceIndex
}
if (-not $activeMatch -or -not $persistentMatch) {
    throw "Route creation could not be verified in both ActiveStore and PersistentStore."
}
Write-Host "Added persistent route: $prefix via $VmIp on $InterfaceAlias"
