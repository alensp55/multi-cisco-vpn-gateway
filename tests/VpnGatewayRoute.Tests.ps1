Import-Module (Join-Path $PSScriptRoot "..\windows\VpnGatewayRoute.psm1") -Force

Describe "VPN route planning" {
    It "creates a host prefix" {
        ConvertTo-VpnHostPrefix -Address "192.0.2.40" | Should -Be "192.0.2.40/32"
    }

    It "rejects an IPv6 address" {
        { ConvertTo-VpnHostPrefix -Address "2001:db8::1" } | Should -Throw
    }

    It "returns Create when no route exists" {
        Get-VpnRouteDecision -ActiveRoutes @() -PersistentRoutes @() -NextHop "192.0.2.10" `
            -InterfaceIndex 8 | Should -Be "Create"
    }

    It "returns Exists for matching active and persistent routes" {
        $route = [pscustomobject]@{ NextHop = "192.0.2.10"; InterfaceIndex = 8 }
        Get-VpnRouteDecision -ActiveRoutes @($route) -PersistentRoutes @($route) -NextHop "192.0.2.10" `
            -InterfaceIndex 8 | Should -Be "Exists"
    }

    It "returns Partial when only one policy store contains the route" {
        $route = [pscustomobject]@{ NextHop = "192.0.2.10"; InterfaceIndex = 8 }
        Get-VpnRouteDecision -ActiveRoutes @($route) -PersistentRoutes @() -NextHop "192.0.2.10" `
            -InterfaceIndex 8 | Should -Be "Partial"
    }

    It "returns Conflict when another next hop exists" {
        $route = [pscustomobject]@{ NextHop = "192.0.2.11"; InterfaceIndex = 8 }
        Get-VpnRouteDecision -ActiveRoutes @($route) -PersistentRoutes @() -NextHop "192.0.2.10" `
            -InterfaceIndex 8 | Should -Be "Conflict"
    }
}
