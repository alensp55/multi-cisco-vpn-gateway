function ConvertTo-VpnHostPrefix {
    param([Parameter(Mandatory)][string]$Address)

    $parsed = $Address -as [ipaddress]
    if (-not $parsed -or $parsed.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
        throw "Expected an IPv4 address."
    }
    return "$Address/32"
}

function Get-VpnRouteDecision {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ActiveRoutes,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$PersistentRoutes,
        [Parameter(Mandatory)][string]$NextHop,
        [Parameter(Mandatory)][int]$InterfaceIndex
    )

    $allRoutes = @($ActiveRoutes) + @($PersistentRoutes)
    $conflicts = @($allRoutes) | Where-Object {
        $_.NextHop -ne $NextHop -or $_.InterfaceIndex -ne $InterfaceIndex
    }
    if ($conflicts.Count -gt 0) {
        return "Conflict"
    }

    $activeMatch = @($ActiveRoutes) | Where-Object {
        $_.NextHop -eq $NextHop -and $_.InterfaceIndex -eq $InterfaceIndex
    }
    $persistentMatch = @($PersistentRoutes) | Where-Object {
        $_.NextHop -eq $NextHop -and $_.InterfaceIndex -eq $InterfaceIndex
    }
    if ($activeMatch -and $persistentMatch) {
        return "Exists"
    }
    if ($activeMatch -or $persistentMatch) {
        return "Partial"
    }
    return "Create"
}

function Get-MatchingVpnRoutes {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Routes,
        [Parameter(Mandatory)][string]$NextHop,
        [Parameter(Mandatory)][int]$InterfaceIndex
    )

    return @($Routes) | Where-Object {
        $_.NextHop -eq $NextHop -and $_.InterfaceIndex -eq $InterfaceIndex
    }
}

Export-ModuleMember -Function ConvertTo-VpnHostPrefix, Get-VpnRouteDecision, Get-MatchingVpnRoutes
