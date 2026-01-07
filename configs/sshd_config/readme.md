# AuditBot Infrastructure: SSH Hardening Protocol (Day 4)

## Overview
This document outlines the security baseline for remote access to the AuditBot environment. By transitioning from legacy password-based authentication to modern asymmetric cryptography, we eliminate 99% of brute-force and credential-stuffing attack vectors.

## Technical Objective
* **Algorithm:** Ed25519 (Elliptic Curve Cryptography)
* **Authentication:** Public-key only (Passwords disabled)
* **Integrity:** Hardened `sshd_config` to follow the Principle of Least Privilege

## 1. Key Generation
We utilize **Ed25519** over RSA because it offers higher security with smaller key sizes (256-bit vs 4096-bit) and is faster for signature verification.

```bash
# Generate the elite key pair
ssh-keygen -t ed25519 -C "AuditBot_CEO_Access"
```
## 2. Key DeploymentDeploy the public key to the target environment/VM.Bash# Automated deployment
ssh-copy-id -i ~/.ssh/id_ed25519.pub [user]@[target_ip]
##3. Server Hardening (The "Kill Switch")Configuration located at /etc/ssh/sshd_config. 
* **The following directives ensure a "Default Deny" posture.**
DirectiveSettingPurposePermitRootLoginnoPrevents direct root-level attacksPasswordAuthenticationnoForces the use of cryptographic keysPubkeyAuthenticationyesEnables the verified key-exchange pathMaxAuthTries3Mitigates automated key-guessing attempts
To apply changes:Bashsudo sshd -t          
# Test config for syntax errors
sudo systemctl restart ssh
4. Why Ed25519? (Specialist Insight)Performance: Significantly faster signing and verification times compared to RSA-4096.Resilience: More robust against Pseudo-Random Number Generator (PRNG) failures than RSA.Compactness: Smaller keys (68 characters) lead to faster handshakes and less storage overhead.5. Verification Checklist[ ] Attempted SSH login as root (Expected: FAIL)[ ] Attempted SSH login with password (Expected: FAIL)[ ] Attempted SSH login with Ed25519 key (Expected: SUCCESS)
