#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/../libexec/vpn-gateway-lib"
}

@test "IPv4 CIDR validator accepts boundary prefixes" {
    is_ipv4_cidr "192.0.2.1/32"
    is_ipv4_cidr "0.0.0.0/0"
}

@test "IPv4 CIDR validator rejects invalid octets and prefixes" {
    ! is_ipv4_cidr "192.0.2.999/32"
    ! is_ipv4_cidr "192.0.2.1/33"
    ! is_ipv4_cidr "192.0.2.1"
}

@test "route arguments preserve every configured network" {
    local targets=("192.0.2.1/32" "198.51.100.0/24")
    local arguments=(--server "https://vpn.example.org")

    append_route_arguments targets arguments

    [ "${arguments[2]}" = "--route" ]
    [ "${arguments[3]}" = "192.0.2.1/32" ]
    [ "${arguments[4]}" = "--route" ]
    [ "${arguments[5]}" = "198.51.100.0/24" ]
}

@test "nft renderer includes only selected targets" {
    run render_nft_rules gateway uplink0 tunnel0 "192.0.2.1/32" "198.51.100.0/24"

    [ "$status" -eq 0 ]
    [[ "$output" == *'iifname "uplink0" oifname "tunnel0"'* ]]
    [[ "$output" == *'192.0.2.1/32, 198.51.100.0/24'* ]]
}

@test "server parser removes scheme path and port" {
    run vpn_server_host "https://vpn.example.org:8443/auth"

    [ "$status" -eq 0 ]
    [ "$output" = "vpn.example.org" ]
}
