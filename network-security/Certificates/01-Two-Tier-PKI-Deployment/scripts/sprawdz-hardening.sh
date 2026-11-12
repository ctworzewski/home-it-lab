#!/usr/bin/env bash
# Odczyt diagnostyczny. Nie modyfikuje konfiguracji.
set -u
printf '\n=== HOST ===\n'; hostnamectl --static
printf '\n=== IP / ROUTING ===\n'; ip -4 addr show eth0; ip -4 route
printf '\n=== DNS ===\n'; grep '^nameserver' /etc/resolv.conf || true
printf '\n=== SSH ===\n'; sudo sshd -T | grep -E '^(port|permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|x11forwarding|allowtcpforwarding) '
printf '\n=== FIREWALL ===\n'; sudo ufw status verbose
printf '\n=== CZAS ===\n'; timedatectl
printf '\n=== UMASK ===\n'; umask
printf '\n=== AUDYT ===\n'; sudo systemctl is-active auditd || true
printf '\n=== LYNIS ===\n'; sudo grep '^hardening_index=' /var/log/lynis-report.dat 2>/dev/null || true
