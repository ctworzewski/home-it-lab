#!/usr/bin/env bash
# Read-only local diagnostics. Run on each PKI VM.
set -u
printf '\n=== Host and time ===\n'
hostnamectl --static
timedatectl | head -n 8
printf '\n=== SSH effective configuration ===\n'
sudo sshd -T | grep -E '^(port|permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication) '
printf '\n=== Firewall ===\n'
sudo ufw status verbose
printf '\n=== User umask ===\n'
umask
printf '\n=== Lynis index (if present) ===\n'
if [ -f /var/log/lynis-report.dat ]; then sudo grep '^hardening_index=' /var/log/lynis-report.dat || true; fi
