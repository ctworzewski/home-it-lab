# 04 — Verification checklist

- [ ] `openssl verify` validates the Issuing CA against Root CA.
- [ ] `basicConstraints` and `keyUsage` are correct on each CA certificate.
- [ ] Server certificate includes subjectAltName for the service DNS name.
- [ ] New certificate chain works on Windows and Linux with installed trusted root.
- [ ] Certificate serial numbers and OpenSSL CA database are consistent.
- [ ] Issuing CRL is accessible and reports correct `thisUpdate` / `nextUpdate`.
- [ ] Root CRL remains available while Root CA is offline.
- [ ] Issuing CA key cannot access Root CA private key or backups.
- [ ] Root CA vNIC is disconnected and offline status documented.
- [ ] A test revocation is published and validated by an appropriate client/tool.
- [ ] Encrypted backup restoration is tested on isolated infrastructure.
- [ ] Expiry monitoring works for issued certificates and CRLs.
