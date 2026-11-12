# 01 — Architecture

## Trust chain

`Root CA (offline)` → `Issuing CA (online)` → `TLS certificates for lab services`.

- **Root CA:** signs and, if needed, revokes Issuing CA certificates; issues its root CRL while offline; private key never present on Issuing CA.
- **Issuing CA:** signs end-entity certificates, manages database, certificate serials and issuance/revocations; publishes CRL.
- **Publication:** certificate chain and CRLs must remain accessible at stable HTTP locations even when Root CA is powered off.

## Decisions to record before issuing certificates

- [ ] Naming of Root/Issuing CA subject DNs and certificate lifetimes
- [ ] Key algorithm, key size, key encryption and passphrase management
- [ ] Final URLs for AIA and CDP (CRL distribution points)
- [ ] Private key handling and physically/logically separated encrypted backup media
- [ ] Transfer procedure for Issuing CSR and signed CA certificate (controlled offline media)
- [ ] CRL renewal schedule and alerts before `nextUpdate`
- [ ] Recovery procedure and trust-anchor deployment

## Offline Root CA

Removing a VM's NIC helps, but is not complete isolation if an attacker can access its host, disks, backup store, checkpoints or management plane. Protect the virtualization host, offline media and encrypted copies. Disable online/automatic update assumptions once offline.
