# Server Hardening & Security Documentation 📚

Complete guide for securing and hardening servers across Windows and Linux platforms.

---

## 📑 Table of Contents

### Phase 1: Foundation (Days 1-5)

#### Day 2: SSH Hardening
- [SSH Hardening - Windows Server](docs/firewalls-windows-server.md)

#### Day 5: Firewalls
- [Firewalls - Linux/Ubuntu (UFW)](docs/day-5-firewalls-ufw.md)
- [Firewalls - Windows Server](docs/day-5-firewalls-windows-server.md)

---

### Phase 2: Development Security (Day 6+)

#### Day 6: Git Security Hooks
- [Git Pre-Commit Hooks - Secret Scanning](docs/day-6-git-security-hooks.md)

---

## 🗂️ Document Structure

Each guide includes:
- ✅ **Objective** - What you'll achieve
- ✅ **Step-by-step instructions** - Both Windows & Linux where applicable
- ✅ **Testing procedures** - Verify everything works
- ✅ **Troubleshooting** - Common issues and solutions
- ✅ **Security best practices** - Industry standards
- ✅ **Screenshots checklist** - Document your work

---

## 🚀 Quick Start

1. **Choose your platform**:  Windows Server or Linux
2. **Follow the days in order**: Build security layer by layer
3. **Test thoroughly**: Verify each configuration before moving forward
4. **Document your progress**: Take screenshots as proof of work

---

## 📊 Progress Tracker

- [ ] Day 1: User Management & Permissions
- [x] Day 2: SSH Hardening
- [ ] Day 3: System Updates & Security Patches
- [ ] Day 4: Fail2Ban / Intrusion Detection
- [x] Day 5: Firewall Configuration
- [x] Day 6: Git Security Hooks
- [ ] Day 7+: Advanced Security

---

## 🛡️ Security Principles

All guides follow these core principles:

1. **Defense in Depth** - Multiple layers of security
2. **Least Privilege** - Minimum necessary permissions
3. **Default Deny** - Block everything, allow selectively
4. **Audit Everything** - Log and monitor all activity
5. **Test Before Deploy** - Verify configurations work

---

## 💻 Supported Platforms

| Platform | SSH | Firewall | Git Hooks |
|----------|-----|----------|-----------|
| **Windows Server 2019+** | ✅ | ✅ | ✅ |
| **Ubuntu/Debian Linux** | ✅ | ✅ | ✅ |
| **CentOS/RHEL** | ✅ | ⚠️ (iptables) | ✅ |
| **macOS** | ✅ | ⚠️ (pf firewall) | ✅ |

---

## 📖 Additional Resources

- [OWASP Security Guidelines](https://owasp.org/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

---

**Project:** AuditBot Security Hardening  
**Status:** In Progress 🚧  
**Last Updated:** January 2026
