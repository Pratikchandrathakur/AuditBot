# AuditBot Infrastructure: SSH Hardening Protocol

<div align="center">

**Enterprise-Grade SSH Security Implementation**

[![SSH](https://img.shields.io/badge/SSH-Ed25519-blue.svg)](https://github.com)
[![Status](https://img.shields.io/badge/Status-Production-success.svg)](https://github.com)

*Eliminating 99% of brute-force and credential-stuffing attack vectors through modern asymmetric cryptography*

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Security Benefits](#security-benefits)
- [Technical Specifications](#technical-specifications)
- [Implementation Guide](#implementation-guide)
- [Configuration Details](#configuration-details)
- [Verification & Testing](#verification--testing)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Contributing](#contributing)
- [License](#license)

---

## 🎯 Overview

This repository documents the **Day 4** security baseline for remote access to the AuditBot infrastructure environment. By transitioning from legacy password-based authentication to modern asymmetric cryptography, we establish a robust defense against unauthorized access attempts.

### Key Transformation

```diff
- ❌ Password-Based Authentication (Vulnerable to brute-force)
+ ✅ Ed25519 Public-Key Cryptography (Cryptographically Secure)
```

---

## 🛡️ Security Benefits

| Feature | Benefit |
|---------|---------|
| **🔐 Zero Password Exposure** | Eliminates credential theft and password reuse attacks |
| **⚡ Ed25519 Algorithm** | 256-bit security with superior performance over RSA-4096 |
| **🚫 Default Deny Posture** | All access denied unless explicitly authorized |
| **🎯 Principle of Least Privilege** | Minimal attack surface through hardened configuration |
| **📊 Audit Trail** | Complete logging of all authentication attempts |

---

## 🔧 Technical Specifications

### Core Objective

- **Algorithm**: Ed25519 (Elliptic Curve Digital Signature Algorithm)
- **Authentication Method**: Public-key cryptography only
- **Password Authentication**: Completely disabled
- **Configuration Standard**: CIS Benchmark aligned

### Why Ed25519?

Ed25519 was chosen for its superior cryptographic properties: 

#### Performance Comparison

```
Algorithm    | Key Size | Sign Time | Verify Time | Security Level
-------------|----------|-----------|-------------|---------------
RSA-4096     | 4096-bit | ~2.3ms    | ~0.1ms      | ~140-bit
Ed25519      | 256-bit  | ~0.04ms   | ~0.1ms      | ~128-bit
```

#### Technical Advantages

1. **🚀 Performance**: Significantly faster signing and verification
2. **💪 Resilience**: Robust against PRNG (Pseudo-Random Number Generator) failures
3. **📦 Compactness**: Smaller keys (68 characters) enable faster handshakes
4. **🔒 Security**: Modern elliptic curve cryptography with proven security
5. **🎯 Deterministic**: Immune to weak random number generation vulnerabilities

---

## 🚀 Implementation Guide

### Step 1: Key Generation

Generate your Ed25519 key pair with a descriptive comment for identification:

```bash
# Generate the cryptographic key pair
ssh-keygen -t ed25519 -C "AuditBot_CEO_Access"
```

**Expected Output:**
```
Generating public/private ed25519 key pair. 
Enter file in which to save the key (/home/user/.ssh/id_ed25519):
Enter passphrase (empty for no passphrase): [Type secure passphrase]
Enter same passphrase again: [Confirm passphrase]
Your identification has been saved in /home/user/.ssh/id_ed25519
Your public key has been saved in /home/user/.ssh/id_ed25519.pub
```

**🔑 Pro Tip**: Always use a strong passphrase to protect your private key. Use a password manager or passphrase generator. 

---

### Step 2: Key Deployment

Deploy your public key to the target server:

```bash
# Automated public key deployment
ssh-copy-id -i ~/.ssh/id_ed25519.pub [user]@[target_ip]
```

**Alternative Manual Method:**

```bash
# Copy public key content
cat ~/.ssh/id_ed25519.pub

# On target server
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "[paste_public_key_here]" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

---

### Step 3: Server Hardening Configuration

Edit the SSH daemon configuration file to enforce security policies:

```bash
# Backup original configuration
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup. $(date +%Y%m%d)

# Edit configuration
sudo nano /etc/ssh/sshd_config
```

#### Critical Security Directives

| Directive | Setting | Security Purpose |
|-----------|---------|------------------|
| `PermitRootLogin` | **no** | Prevents direct root-level attacks |
| `PasswordAuthentication` | **no** | Forces cryptographic key usage |
| `PubkeyAuthentication` | **yes** | Enables verified key-exchange |
| `MaxAuthTries` | **3** | Mitigates automated brute-force |
| `PermitEmptyPasswords` | **no** | Blocks empty password exploitation |
| `ChallengeResponseAuthentication` | **no** | Disables keyboard-interactive auth |
| `UsePAM` | **yes** | Enables Pluggable Authentication Modules |
| `X11Forwarding` | **no** | Reduces attack surface (if not needed) |

#### Complete Hardened Configuration

```bash
# /etc/ssh/sshd_config - AuditBot Security Baseline

# Authentication Methods
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
PermitEmptyPasswords no
MaxAuthTries 3

# Key Algorithms (Prefer Modern Cryptography)
PubkeyAcceptedKeyTypes ssh-ed25519,ssh-ed25519-cert-v01@openssh.com

# Security Hardening
Protocol 2
StrictModes yes
MaxSessions 10
LoginGraceTime 60

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Disable Unnecessary Features
X11Forwarding no
AllowTcpForwarding no
PermitTunnel no
```

---

### Step 4: Apply and Validate Configuration

```bash
# Test configuration for syntax errors
sudo sshd -t

# If test passes, restart SSH service
sudo systemctl restart ssh

# Verify service status
sudo systemctl status ssh
```

**⚠️ Critical Warning**: Always maintain an active SSH session while testing configuration changes. This prevents lockout scenarios.

---

## ✅ Verification & Testing

### Security Validation Checklist

Use this checklist to verify your hardening implementation:

- [ ] **Test 1**: Attempted SSH login as root → **Expected: FAIL**
  ```bash
  ssh root@[target_ip]
  # Should return: Permission denied
  ```

- [ ] **Test 2**: Attempted SSH login with password → **Expected:  FAIL**
  ```bash
  ssh -o PubkeyAuthentication=no [user]@[target_ip]
  # Should return: Permission denied (publickey)
  ```

- [ ] **Test 3**: Attempted SSH login with Ed25519 key → **Expected: SUCCESS**
  ```bash
  ssh -i ~/.ssh/id_ed25519 [user]@[target_ip]
  # Should successfully authenticate
  ```

### Monitoring Authentication Attempts

```bash
# View recent authentication logs
sudo tail -f /var/log/auth.log

# Search for failed attempts
sudo grep "Failed password" /var/log/auth.log

# Monitor SSH service in real-time
sudo journalctl -u ssh -f
```

---

## 🔍 Troubleshooting

### Common Issues and Solutions

#### Issue: "Permission denied (publickey)"

**Diagnosis:**
```bash
# Test with verbose output
ssh -vvv -i ~/.ssh/id_ed25519 [user]@[target_ip]
```

**Solutions:**
1. Verify public key is in `~/.ssh/authorized_keys` on server
2. Check file permissions: `chmod 600 ~/.ssh/authorized_keys`
3. Ensure SSH directory permissions: `chmod 700 ~/.ssh`
4. Verify private key permissions: `chmod 600 ~/.ssh/id_ed25519`

#### Issue: Configuration test fails

```bash
# Check syntax errors
sudo sshd -t

# View detailed error
sudo sshd -T
```

#### Issue: Locked out of server

**Prevention:**
- Always keep one active SSH session open while testing
- Use console access if available (cloud provider dashboard)
- Configure serial console access as backup

**Recovery:**
- Access via cloud provider console/emergency access
- Restore backup configuration:  `sudo cp /etc/ssh/sshd_config.backup.[date] /etc/ssh/sshd_config`
- Restart SSH service

---

## 📚 Best Practices

### 🔐 Key Management

1. **Protect Private Keys**: Never share or transmit private keys
2. **Use Passphrases**: Always encrypt private keys with strong passphrases
3. **Key Rotation**: Rotate keys annually or after personnel changes
4. **Backup Keys**: Store encrypted backups in secure locations
5. **Separate Keys**: Use different keys for different environments (dev/staging/prod)

### 🛡️ Operational Security

1. **Principle of Least Privilege**: Grant minimum necessary access
2. **Regular Audits**: Review `authorized_keys` files periodically
3. **Monitoring**: Implement centralized logging and alerting
4. **Updates**: Keep OpenSSH updated to latest stable version
5. **Bastion Hosts**: Consider jump servers for production access

### 📊 Compliance Considerations

This configuration aligns with:
- CIS Benchmarks for SSH
- NIST SP 800-52 Rev.  2
- PCI DSS Requirement 2.3
- SOC 2 Type II controls

---

## 🤝 Contributing

Contributions to improve this security baseline are welcome. Please follow these guidelines:

1. **Security Focus**: All contributions must enhance security posture
2. **Documentation**: Include clear explanations for changes
3. **Testing**: Verify changes in isolated environments
4. **Compliance**: Ensure alignment with industry standards

### Reporting Security Issues

If you discover a security vulnerability, please report it privately: 
- **Email**: security@auditbot. example.com
- **Do NOT**: Create public issues for security vulnerabilities

---

## 📄 License

This security documentation is provided as-is for educational and implementation purposes. 

---

## 🔗 Additional Resources

### Official Documentation
- [OpenSSH Official Documentation](https://www.openssh.com/)
- [Ed25519 Specification (RFC 8032)](https://tools.ietf.org/html/rfc8032)

### Security Guidelines
- [CIS OpenSSH Benchmark](https://www.cisecurity.org/)
- [Mozilla SSH Guidelines](https://infosec.mozilla.org/guidelines/openssh)
- [NIST Cryptographic Standards](https://csrc.nist.gov/)

### Learning Resources
- [SSH Academy](https://www.ssh.com/academy/ssh)
- [Understanding Public Key Cryptography](https://en.wikipedia.org/wiki/Public-key_cryptography)

---

## 📞 Support

For questions or assistance with implementation: 

- **Documentation Issues**: Open an issue in this repository
- **Security Concerns**:  Contact security team directly
- **Implementation Support**: Consult your infrastructure team

---

<div align="center">

**🔒 Security is not a product, but a process 🔒**

*Implemented with care by the AuditBot Infrastructure Team*

**Day 4 of Security Excellence Journey**

</div>

---

## 📝 Changelog

### Version 1.0.0 (Day 4)
- ✅ Initial SSH hardening implementation
- ✅ Ed25519 key-based authentication
- ✅ Password authentication disabled
- ✅ Root login disabled
- ✅ Comprehensive documentation
---

**Made with 🔒 for a more secure infrastructure**
