# Day 2: SSH Hardening (OpenSSH Server) 🔐🪟

**Date:** January 2, 2026  
**Phase:** 1 - Foundation  
**Goal:** Secure remote access with key-based authentication and disable password logins.

---

## 🎯 Objective

Harden OpenSSH Server on Windows Server by implementing key-based authentication, disabling password logins, and configuring secure SSH settings to prevent unauthorized access.

---

## 📚 Background

**OpenSSH Server** is now natively available in Windows Server 2019 and later. It provides secure remote command-line access as an alternative to Remote Desktop Protocol (RDP).

### Why SSH Hardening Matters:
- **Password Attacks**: Password-based authentication is vulnerable to brute force attacks
- **Key-Based Auth**: SSH keys are exponentially more secure than passwords
- **Reduced Attack Surface**:  Proper configuration prevents common SSH exploits
- **Compliance**: Many security frameworks require strong authentication methods

### Windows SSH vs Linux SSH:
- Configuration file: `C:\ProgramData\ssh\sshd_config`
- Service name: `sshd` (managed via Windows Services)
- Default port: 22 (same as Linux)
- Key storage: User profile directories

---

## ⚡ Implementation Steps

### Prerequisites

Open **PowerShell as Administrator** for all commands. 

---

## Part 1: Install OpenSSH Server

### 1. Check if OpenSSH is Already Installed

```powershell
# Check OpenSSH Server installation status
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH. Server*'
```

**Output if not installed:**
```
Name  : OpenSSH.Server~~~~0. 0.1.0
State : NotPresent
```

---

### 2. Install OpenSSH Server

```powershell
# Install OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Verify installation
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
```

**Expected Output:**
```
Name  : OpenSSH.Server~~~~0.0.1.0
State :  Installed
```

---

### 3. Start and Enable SSH Service

```powershell
# Start the SSH service
Start-Service sshd

# Set SSH to start automatically on boot
Set-Service -Name sshd -StartupType 'Automatic'

# Verify service is running
Get-Service sshd
```

**Expected Output:**
```
Status   Name               DisplayName
------   ----               -----------
Running  sshd               OpenSSH SSH Server
```

---

### 4. Configure Windows Firewall

```powershell
# Check if SSH firewall rule exists
Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue

# If not present, create the rule
New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' `
    -DisplayName 'OpenSSH Server (sshd)' `
    -Enabled True `
    -Direction Inbound `
    -Protocol TCP `
    -Action Allow `
    -LocalPort 22 `
    -Profile Any

# Verify the rule
Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" | Select-Object DisplayName, Enabled, Direction, Action
```

---

## Part 2: Configure SSH Key-Based Authentication

### 5. Generate SSH Key Pair (On Your Local Machine)

**On Windows (PowerShell):**
```powershell
# Generate ED25519 key (recommended - more secure and faster)
ssh-keygen -t ed25519 -C "your-email@example.com"

# Alternative: Generate RSA key (if ED25519 not supported)
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

**On Linux/Mac (Terminal):**
```bash
# Generate ED25519 key
ssh-keygen -t ed25519 -C "your-email@example. com"

# Alternative: Generate RSA key
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

**Output:**
```
Generating public/private ed25519 key pair.
Enter file in which to save the key (C:\Users\YourName\.ssh\id_ed25519):
Enter passphrase (empty for no passphrase): [Type a strong passphrase]
Enter same passphrase again: [Retype passphrase]
```

**Important:** 
- Save keys in default location (`~/.ssh/id_ed25519` or `~/.ssh/id_rsa`)
- **Always use a passphrase** for additional security
- Your private key (`id_ed25519`) stays on your local machine
- Your public key (`id_ed25519.pub`) will be copied to the server

---

### 6. Copy Public Key to Windows Server

**Method 1: Using PowerShell (Recommended)**

On your **local machine**, copy your public key: 

```powershell
# View your public key
Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub"
```

On the **Windows Server**, run: 

```powershell
# For regular users (non-administrators)
$publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGq...  your-email@example.com"

# Create . ssh directory if it doesn't exist
$sshFolder = "$env:USERPROFILE\.ssh"
if (-not (Test-Path $sshFolder)) {
    New-Item -ItemType Directory -Path $sshFolder -Force
}

# Add public key to authorized_keys
Add-Content -Path "$sshFolder\authorized_keys" -Value $publicKey

# Set proper permissions (critical!)
icacls "$sshFolder\authorized_keys" /inheritance:r
icacls "$sshFolder\authorized_keys" /grant: r "$env:USERNAME: F"
```

**Method 2: For Administrator Accounts**

Administrators use a different location:

```powershell
# For administrators only
$publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGq... your-email@example.com"

# Path for administrators
$adminAuthKeysPath = "C:\ProgramData\ssh\administrators_authorized_keys"

# Add public key
Add-Content -Path $adminAuthKeysPath -Value $publicKey

# Set proper permissions (CRITICAL for admins!)
icacls $adminAuthKeysPath /inheritance:r
icacls $adminAuthKeysPath /grant "BUILTIN\Administrators: F"
icacls $adminAuthKeysPath /grant "SYSTEM:F"
```

---

### 7. Test SSH Key Authentication

From your **local machine**:

```powershell
# Test SSH connection with key
ssh username@your-server-ip

# If using a non-default key location
ssh -i C:\path\to\your\private_key username@your-server-ip
```

**Expected:**
- You'll be prompted for your **key passphrase** (not server password)
- Successful login means key authentication is working! 

---

## Part 3: Harden SSH Configuration

### 8. Backup Original Configuration

```powershell
# Backup the original sshd_config
Copy-Item "C:\ProgramData\ssh\sshd_config" "C:\ProgramData\ssh\sshd_config.backup. $(Get-Date -Format 'yyyyMMdd-HHmmss')"
```

---

### 9. Edit SSH Configuration File

```powershell
# Open sshd_config in Notepad with admin privileges
notepad C:\ProgramData\ssh\sshd_config
```

**Recommended Hardening Settings:**

```bash
# Port Configuration
Port 22                              # Default port (consider changing to non-standard port for obscurity)

# Authentication Settings
PermitRootLogin no                   # Disable root login (use Administrator account name instead)
PasswordAuthentication no            # DISABLE password authentication (keys only!)
PubkeyAuthentication yes             # ENABLE public key authentication
PermitEmptyPasswords no              # Never allow empty passwords
ChallengeResponseAuthentication no   # Disable challenge-response authentication

# Session Settings
MaxAuthTries 3                       # Limit authentication attempts
MaxSessions 3                        # Limit concurrent sessions
LoginGraceTime 30                    # Reduce login time window (30 seconds)
ClientAliveInterval 300              # Send keepalive every 5 minutes
ClientAliveCountMax 2                # Disconnect after 2 missed keepalives (10 min total)

# Security Protocols
Protocol 2                           # Use SSH Protocol 2 only (SSH1 is insecure)

# Access Control
AllowUsers username1 username2       # Whitelist specific users (replace with your usernames)
# DenyUsers baduser                  # Blacklist specific users (optional)
# AllowGroups sshusers               # Whitelist specific groups (optional)

# Logging
SyslogFacility AUTH                  # Log authentication messages
LogLevel INFO                        # Log level (use VERBOSE for troubleshooting)

# Disable Unnecessary Features
X11Forwarding no                     # Disable X11 forwarding (not needed on Windows)
AllowTcpForwarding no                # Disable TCP forwarding (enable only if needed)
AllowAgentForwarding no              # Disable agent forwarding (enable only if needed)
PermitTunnel no                      # Disable tunneling (enable only if needed)
GatewayPorts no                      # Disable gateway ports

# Banner (optional - show warning message)
Banner C:\ProgramData\ssh\banner.txt

# Host Keys (ensure these are enabled)
HostKey C:/ProgramData/ssh/ssh_host_rsa_key
HostKey C:/ProgramData/ssh/ssh_host_ecdsa_key
HostKey C:/ProgramData/ssh/ssh_host_ed25519_key
```

**Save and close Notepad.**

---

### 10. Create SSH Banner (Optional but Recommended)

```powershell
# Create banner file
$bannerText = @"
***************************************************************************
                      AUTHORIZED ACCESS ONLY
                      
This system is for authorized use only.  All activity is monitored and logged. 
Unauthorized access is strictly prohibited and will be prosecuted. 

By accessing this system, you consent to monitoring and recording. 
***************************************************************************
"@

Set-Content -Path "C:\ProgramData\ssh\banner.txt" -Value $bannerText
```

---

### 11. Configure User Access Whitelist

```powershell
# List all local users
Get-LocalUser | Select-Object Name, Enabled

# Edit sshd_config to allow specific users
# Add this line to sshd_config:
# AllowUsers your-username admin-username
```

**Example:**
```
AllowUsers jdoe serveradmin
```

---

### 12. Restart SSH Service

```powershell
# Restart sshd to apply configuration changes
Restart-Service sshd

# Verify service is running
Get-Service sshd

# Check for configuration errors
Get-EventLog -LogName Application -Source sshd -Newest 10
```

---

## Part 4: Verification & Testing

### 13. Test SSH Connection (From Local Machine)

**Test 1: Key-Based Authentication (Should Work)**
```powershell
ssh username@your-server-ip
```
✅ **Expected:** Prompted for key passphrase, successful login

---

**Test 2: Password Authentication (Should Fail)**
```powershell
ssh -o PubkeyAuthentication=no username@your-server-ip
```
❌ **Expected:** 
```
username@your-server-ip: Permission denied (publickey).
```

This confirms password authentication is disabled!

---

**Test 3: Invalid User (Should Fail)**
```powershell
ssh invaliduser@your-server-ip
```
❌ **Expected:**
```
invaliduser@your-server-ip: Permission denied (publickey).
```

---

### 14. Check SSH Logs (On Server)

```powershell
# View SSH-related events in Windows Event Viewer
Get-EventLog -LogName Application -Source sshd -Newest 20 | 
    Format-Table -AutoSize TimeGenerated, EntryType, Message

# Filter for authentication events
Get-EventLog -LogName Security -Newest 50 | 
    Where-Object { $_.EventID -eq 4624 -or $_.EventID -eq 4625 } |
    Format-Table -AutoSize TimeGenerated, EventID, Message
```

**Event IDs to monitor:**
- **4624**:  Successful logon
- **4625**: Failed logon attempt
- **4634**:  Logoff

---

## 🔐 Advanced Hardening (Optional)

### 15. Change SSH Default Port (Security Through Obscurity)

**Edit sshd_config:**
```bash
Port 2222  # Change from 22 to non-standard port
```

**Update Firewall Rule:**
```powershell
# Remove old rule
Remove-NetFirewallRule -Name "OpenSSH-Server-In-TCP"

# Add new rule with custom port
New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' `
    -DisplayName 'OpenSSH Server (sshd) - Port 2222' `
    -Enabled True `
    -Direction Inbound `
    -Protocol TCP `
    -Action Allow `
    -LocalPort 2222 `
    -Profile Any

# Restart SSH
Restart-Service sshd
```

**Connect with custom port:**
```powershell
ssh -p 2222 username@your-server-ip
```

---

### 16. Implement Fail2Ban Alternative (Windows)

While Fail2Ban is Linux-specific, you can use **Windows built-in features**:

**Option 1: Account Lockout Policy**
```powershell
# Set account lockout threshold
net accounts /lockoutthreshold:3

# Set lockout duration (30 minutes)
net accounts /lockoutduration:30

# Set lockout observation window (30 minutes)
net accounts /lockoutwindow:30

# Verify settings
net accounts
```

**Option 2: Use Third-Party Tools**
- **EventSentry** - Monitor failed SSH attempts
- **OSSEC** - Host-based intrusion detection
- **Wazuh** - Security monitoring platform

---

### 17. Restrict SSH by IP Address

**Edit Firewall Rule to Allow Only Specific IPs:**

```powershell
# Remove existing rule
Remove-NetFirewallRule -Name "OpenSSH-Server-In-TCP"

# Create restricted rule (only allow from specific IP/subnet)
New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' `
    -DisplayName 'OpenSSH Server (Restricted)' `
    -Enabled True `
    -Direction Inbound `
    -Protocol TCP `
    -Action Allow `
    -LocalPort 22 `
    -RemoteAddress 203.0.113.0/24 `
    -Profile Any
```

**Allow Multiple IPs:**
```powershell
New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' `
    -DisplayName 'OpenSSH Server (Restricted)' `
    -Enabled True `
    -Direction Inbound `
    -Protocol TCP `
    -Action Allow `
    -LocalPort 22 `
    -RemoteAddress @('203.0.113.50', '198.51.100.100', '192.0.2.0/24') `
    -Profile Any
```

---

### 18. Enable Two-Factor Authentication (2FA)

**Install Google Authenticator for Windows SSH:**

This requires third-party PAM modules, which are experimental on Windows.  For production, consider: 
- **Duo Security** (enterprise solution)
- **Azure MFA** (if using Azure AD)
- **VPN + SSH** (SSH only accessible via VPN)

---

## 📊 What We Achieved

✅ **OpenSSH Server Installed** - Native Windows SSH support enabled  
✅ **Key-Based Authentication** - Secure cryptographic authentication configured  
✅ **Password Auth Disabled** - Eliminated brute-force password attacks  
✅ **SSH Hardened** - Disabled unnecessary features and limited access  
✅ **Firewall Configured** - Only SSH port exposed with optional IP restrictions  
✅ **Logging Enabled** - Authentication attempts tracked in Event Viewer  
✅ **Banner Deployed** - Legal warning displayed to all users

---

## 🛡️ Security Benefits

1. **Eliminated Password Attacks**: SSH keys are immune to brute force
2. **Reduced Attack Surface**: Disabled unnecessary SSH features
3. **Access Control**: User whitelist prevents unauthorized accounts
4. **Session Management**: Automatic disconnection of idle sessions
5. **Audit Trail**: Comprehensive logging for security investigations
6. **Compliance**: Meets requirements for PCI-DSS, HIPAA, SOC 2

---

## 🆚 SSH on Windows vs Linux

| Feature | Windows Server | Linux Server |
|---------|----------------|--------------|
| **Installation** | `Add-WindowsCapability` | `apt install openssh-server` |
| **Config File** | `C:\ProgramData\ssh\sshd_config` | `/etc/ssh/sshd_config` |
| **Service Name** | `sshd` | `sshd` or `ssh` |
| **User Keys** | `%USERPROFILE%\.ssh\authorized_keys` | `~/.ssh/authorized_keys` |
| **Admin Keys** | `C:\ProgramData\ssh\administrators_authorized_keys` | `~/.ssh/authorized_keys` |
| **Logs** | Windows Event Viewer | `/var/log/auth.log` |
| **Default Shell** | PowerShell or CMD | Bash |
| **Restart Command** | `Restart-Service sshd` | `systemctl restart sshd` |

---

## 🔍 Troubleshooting

### Issue: Key Authentication Not Working

**Solution 1: Check File Permissions**
```powershell
# For regular users
icacls "$env:USERPROFILE\. ssh\authorized_keys" /inheritance:r
icacls "$env:USERPROFILE\.ssh\authorized_keys" /grant:r "$env:USERNAME:F"

# For administrators
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /grant "BUILTIN\Administrators:F"
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /grant "SYSTEM:F"
```

**Solution 2: Check Configuration**
```powershell
# Ensure these lines are in sshd_config
# PubkeyAuthentication yes
# PasswordAuthentication no

# Restart SSH
Restart-Service sshd
```

**Solution 3: Enable Verbose Logging**
```powershell
# Edit sshd_config
# Change:  LogLevel INFO
# To: LogLevel VERBOSE

Restart-Service sshd

# Check logs
Get-EventLog -LogName Application -Source sshd -Newest 10
```

---

### Issue: Connection Refused

**Solution:**
```powershell
# Check if service is running
Get-Service sshd

# Check if port is listening
netstat -an | Select-String ":22"

# Check firewall rule
Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP"

# Test from local machine first
ssh localhost
```

---

### Issue: Administrator Can't Login with Keys

**Solution:**
Administrators must use the special `administrators_authorized_keys` file:

```powershell
# Copy your public key to admin location
$publicKey = Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub"
Set-Content -Path "C:\ProgramData\ssh\administrators_authorized_keys" -Value $publicKey

# Set STRICT permissions (this is critical!)
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /grant "BUILTIN\Administrators:F"
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /grant "SYSTEM:F"

# Verify permissions - should show ONLY Administrators and SYSTEM
icacls "C:\ProgramData\ssh\administrators_authorized_keys"
```

---

## 📖 Additional Resources

- [Microsoft:  OpenSSH Server Configuration for Windows](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_server_configuration)
- [Microsoft: OpenSSH Key Management](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement)
- [SSH. com: SSH Protocol](https://www.ssh.com/academy/ssh/protocol)
- [NIST: SSH Security Guidelines](https://csrc.nist.gov/publications)

---

## 🚀 Next Steps

**Day 3**:  Windows Updates & Patch Management
- Configure Windows Update
- Install security patches
- Automate update scheduling

**Day 4**: Intrusion Detection
- Configure Advanced Audit Policy
- Implement Log Monitoring
- Set up alerts for suspicious activity

**Day 5**: Firewall Hardening (Already Complete!)

---

## 💡 Key Takeaways

> "SSH keys are like having a 4096-character password that changes every session. Password authentication is like using 'Password123' forever."

- **Never use password authentication** on production servers
- **Always use a passphrase** on your private keys
- **Whitelist users** explicitly - don't allow all accounts
- **Monitor logs** regularly for failed authentication attempts
- **Test before enforcing** - always verify key auth works before disabling passwords
- **Document your configuration** - future you will thank present you

---

## ⚠️ CRITICAL WARNINGS

### 🚨 Before Disabling Password Authentication: 

1. ✅ **Verify key-based auth works** - test multiple times
2. ✅ **Have multiple authorized keys** - backup access method
3. ✅ **Keep an RDP session open** - fallback access while testing
4. ✅ **Document your SSH key location** - don't lose your only key
5. ✅ **Backup your private key** - store securely (encrypted USB, password manager)

### 🚨 If You Get Locked Out:

1. **Use RDP** to access the server (Port 3389)
2. Re-enable password authentication temporarily: 
   ```powershell
   # Edit sshd_config
   # Change: PasswordAuthentication no
   # To: PasswordAuthentication yes
   Restart-Service sshd
   ```
3. Fix your key configuration
4. Test key authentication
5. Disable password authentication again

---

## 📸 Screenshot Checklist

Document your work with these screenshots:

1. ✅ `Get-Service sshd` output (showing Running status)
2. ✅ `Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP"` output
3. ✅ Successful SSH connection using key authentication
4. ✅ Failed connection when trying password authentication
5. ✅ `Get-EventLog` showing SSH authentication events
6. ✅ Contents of `sshd_config` (with sensitive info redacted)

Save these to your GitHub repository as proof of completion! 

---

**Status:** ✅ Complete  
**Phase 1 Progress:** 2/5 Days Complete 🎉  
**Security Level:** 🔒🔒🔒🔒⚪ (4/5 - Hardened)

---

## 🎓 Bonus: SSH Key Management Best Practices

### Naming Conventions
```
~/.ssh/
├── id_ed25519                 # Default private key
├── id_ed25519.pub             # Default public key
├── id_rsa_work                # Work-specific key
├── id_rsa_work.pub
├── id_ed25519_personal        # Personal projects key
├── id_ed25519_personal.pub
└── config                     # SSH client configuration
```

### SSH Config File (On Your Local Machine)
```bash
# ~/.ssh/config (Windows:  C:\Users\YourName\. ssh\config)

# Work Server
Host work-server
    HostName 203.0.113.50
    User administrator
    Port 22
    IdentityFile ~/.ssh/id_ed25519_work
    
# Personal Server
Host personal-vps
    HostName 198.51.100.100
    User myuser
    Port 2222
    IdentityFile ~/. ssh/id_ed25519_personal
    
# Default settings for all hosts
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    Compression yes
```

**Usage:**
```powershell
# Instead of:  ssh administrator@203.0.113.50
# Just use: ssh work-server
```

---
