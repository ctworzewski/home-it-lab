# 03 — Deployment plan (not yet executed)

1. Confirm this is a **new lab PKI**, distinct from production. Decide stable CA names, AIA/CDP HTTP URLs and backup plan.
2. Take protected configuration-only backups. Verify local console access to Root CA. Disconnect Root CA vNIC in Hyper-V **before** generating its private key.
3. Prepare OpenSSL Root CA directory, database (`index.txt`, `serial`, `crlnumber`) and audited OpenSSL configuration.
4. Generate Root CA encrypted private key offline, create self-signed CA certificate with `basicConstraints = critical, CA:TRUE` and appropriate key usages.
5. Prepare Issuing CA with its own private key and CSR. Transfer CSR to Root CA over controlled media.
6. Sign intermediate with offline Root CA. Verify issuer, subject, path length, key usages and validity; transfer resulting certificate and chain back.
7. Generate and publish Root CA and Issuing CA CRLs. Confirm URLs match embedded CDP/AIA extensions. Make CRL renewal operational without leaving Root CA online.
8. Issue a lab server TLS certificate with SAN, test trust path and CRL validation from a client.
9. Document expiry monitoring, encrypted backup/recovery and revocation procedure.

**Never run commands that reset `serial` or `index.txt` on an existing CA database.**
