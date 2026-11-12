# 02 — Debian 13 hardening — completed preparation

## Verified settings

| Item | Value |
|---|---|
| Linux distribution | Debian 13 |
| Administration account | `pkiadmin` |
| SSH | TCP 2352, Ed25519 client keys |
| SSH root login | Disabled |
| SSH password and keyboard interactive auth | Disabled |
| UFW | Active; SSH restricted |
| Admin umask | 0077 |
| Lab gateway / primary DNS | `10.1.201.1` |
| Backup public DNS during provisioning | `8.8.8.8` |
| Time sync | systemd-timesyncd, Europe/Warsaw |
| Audit | auditd; Wazuh monitoring on Issuing CA |
| Malware scanner | ClamAV CLI on Issuing CA |
| Lynis | Issuing CA 77/100 (2026-11-12) |

## Verification-only commands

```bash
hostnamectl
timedatectl
sudo ufw status verbose
sudo sshd -T | grep -E '^(port|permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication) '
umask
sudo auditctl -l
sudo grep '^hardening_index=' /var/log/lynis-report.dat
```

Do not place private keys or sensitive command outputs in public screenshots. Redact secrets and environment-sensitive details.
