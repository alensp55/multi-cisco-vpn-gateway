# Security notes

- Never commit `vpn-gateway.conf`, passwords, cookies, MFA seeds, private certificates, or diagnostic logs.
- Use this only in a dedicated VM. Do not install it on a multi-user workstation or server.
- The installer grants the selected user passwordless access to OpenConnect. OpenConnect supports privileged helper
  scripts, so this permission must be treated as security-sensitive even though it is narrower than `NOPASSWD: ALL`.
- nftables forwards only destinations listed in `VPN_TARGETS` and applies masquerading only toward the VPN interface.
- `WRITE_STATIC_RESOLV_CONF=true` replaces Ubuntu's managed `/etc/resolv.conf`. Use it only when required and keep a
  reachable pre-VPN resolver in `DNS_SERVERS`.
- SAML credentials remain managed by `openconnect-saml` and the desktop keyring. This repository does not implement a
  plaintext password store.
- Review your VPN policy. Some organizations prohibit simultaneous VPN clients, alternate clients, or forwarding.
