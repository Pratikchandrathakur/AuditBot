# Day 5: Firewalls (Windows Defender Firewall) 🔥🛡️

**Date:** January 5, 2026  
**Phase:** 1 - Foundation  
**Goal:** Block all doors except the one you watch. 

---

## 🎯 Objective

Lock down Windows Server networking to ignore all traffic except RDP (Remote Desktop) and essential services. This ensures that only authorized services are accessible from the outside world.

---

## 📚 Background

**Windows Defender Firewall with Advanced Security** is the built-in firewall solution for Windows Server. It provides both inbound and outbound filtering with support for profiles (Domain, Private, Public).

### Why Firewalls Matter:
- **Defense in Depth**: Even if a service has a vulnerability, the firewall can prevent unauthorized access
- **Attack Surface Reduction**:  Only expose the ports you actually need
- **Default Deny**: Block everything by default, then explicitly allow what's necessary

---

## ⚡ Implementation Steps

### Method 1: PowerShell (Recommended for Automation)

Open **PowerShell as Administrator** and follow these steps:

---

### 1. Check Current Firewall Status

```powershell
# View current firewall status for all profiles
Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
```

---

### 2. Set Default Policies (The Base)

```powershell
# Enable firewall for all profiles
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Set default to BLOCK all incoming traffic
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block

# Set default to ALLOW all outgoing traffic
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Allow

# Enable logging
Set-NetFirewallProfile -Profile Domain,Public,Private -LogAllowed True -LogBlocked True -LogMaxSizeKilobytes 4096
```

**What this does:**
- Enables firewall across all network profiles (Domain, Public, Private)
- Blocks all inbound connections unless explicitly allowed
- Allows outbound connections (for Windows Updates, etc.)
- Enables logging for security auditing

---

### 3. The Lifeline (CRITICAL ⚠️)

**WARNING:** If you skip this step, you WILL lock yourself out via RDP! 

```powershell
# Allow Remote Desktop (RDP) - Port 3389
New-NetFirewallRule -DisplayName "Allow RDP (TCP-In)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 3389 `
    -Action Allow `
    -Profile Any `
    -Enabled True

# Optional: Allow web traffic if hosting websites
New-NetFirewallRule -DisplayName "Allow HTTP (TCP-In)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 80 `
    -Action Allow `
    -Profile Any `
    -Enabled True

New-NetFirewallRule -DisplayName "Allow HTTPS (TCP-In)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 443 `
    -Action Allow `
    -Profile Any `
    -Enabled True
```

**Why this matters:**
- Port 3389 is required for Remote Desktop (RDP) access
- Without this rule, you'll be locked out of your server
- Ports 80/443 are safe to add now if you plan to host IIS/web services

---

### 4. Additional Essential Rules

```powershell
# Allow ICMP (Ping) - Optional but useful for network diagnostics
New-NetFirewallRule -DisplayName "Allow ICMPv4 (Ping)" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -Action Allow `
    -Profile Any `
    -Enabled True

# Allow DNS (if this is a DNS server)
New-NetFirewallRule -DisplayName "Allow DNS (UDP-In)" `
    -Direction Inbound `
    -Protocol UDP `
    -LocalPort 53 `
    -Action Allow `
    -Profile Any `
    -Enabled True

# Allow SQL Server (if running SQL Server)
New-NetFirewallRule -DisplayName "Allow SQL Server (TCP-In)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 1433 `
    -Action Allow `
    -Profile Any `
    -Enabled True
```

**Note:** Only add rules for services you're actually running! 

---

### 5. Verification (Proof of Work)

```powershell
# Check firewall status
Get-NetFirewallProfile | Format-Table Name, Enabled, DefaultInboundAction, DefaultOutboundAction

# List all custom inbound rules
Get-NetFirewallRule -Direction Inbound -Enabled True | 
    Where-Object { $_.DisplayName -like "*Allow*" } | 
    Select-Object DisplayName, Enabled, Action, Direction | 
    Format-Table -AutoSize

# View specific port rules
Get-NetFirewallPortFilter | Where-Object { $_.LocalPort -eq 3389 -or $_.LocalPort -eq 80 -or $_.LocalPort -eq 443 }
```

**Expected Output:**
```
Name     Enabled DefaultInboundAction DefaultOutboundAction
----     ------- -------------------- ---------------------
Domain   True    Block                Allow
Private  True    Block                Allow
Public   True    Block                Allow
```

---

## 🖥️ Method 2: GUI (Windows Defender Firewall with Advanced Security)

### Step-by-Step GUI Configuration:

1. **Open Windows Defender Firewall:**
   - Press `Win + R`, type `wf.msc`, press Enter

2. **Configure Default Policies:**
   - Click "Windows Defender Firewall Properties"
   - For each profile (Domain, Private, Public):
     - **Firewall state:** On
     - **Inbound connections:** Block (default)
     - **Outbound connections:** Allow (default)
   - Click "Apply"

3. **Create Inbound Rules:**
   - Click "Inbound Rules" → "New Rule..."
   - **Rule Type:** Port → Next
   - **Protocol:** TCP
   - **Specific local ports:** 3389 (for RDP)
   - **Action:** Allow the connection
   - **Profile:** Check all (Domain, Private, Public)
   - **Name:** Allow RDP (TCP-In)
   - Click "Finish"

4. **Repeat for other ports** (80, 443, etc.)

---

## 🧪 Testing the Firewall

### Test RDP Access

From another machine: 

```powershell
# Test RDP port connectivity
Test-NetConnection -ComputerName your-server-ip -Port 3389
```

**Expected Output:**
```
TcpTestSucceeded : True
```

---

### Test Blocked Ports

Try connecting to a non-allowed port:

```powershell
# Test a blocked port (should fail)
Test-NetConnection -ComputerName your-server-ip -Port 8080
```

**Expected Output:**
```
TcpTestSucceeded : False
```

---

### Test Web Ports (if enabled)

```powershell
Test-NetConnection -ComputerName your-server-ip -Port 80
Test-NetConnection -ComputerName your-server-ip -Port 443
```

---

## 🔍 Common PowerShell Commands

### View Rules

```powershell
# List all enabled inbound rules
Get-NetFirewallRule -Direction Inbound -Enabled True

# List all firewall rules with port information
Get-NetFirewallRule | Get-NetFirewallPortFilter

# Export firewall rules to CSV
Get-NetFirewallRule | Export-Csv -Path C:\firewall-rules.csv
```

### Modify Rules

```powershell
# Disable a rule
Set-NetFirewallRule -DisplayName "Allow HTTP (TCP-In)" -Enabled False

# Enable a rule
Set-NetFirewallRule -DisplayName "Allow HTTP (TCP-In)" -Enabled True

# Remove a rule
Remove-NetFirewallRule -DisplayName "Allow HTTP (TCP-In)"
```

### Advanced Filtering

```powershell
# Allow RDP only from a specific IP
New-NetFirewallRule -DisplayName "Allow RDP from Admin IP" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 3389 `
    -RemoteAddress 203.0.113.50 `
    -Action Allow `
    -Profile Any

# Block a specific IP address
New-NetFirewallRule -DisplayName "Block Malicious IP" `
    -Direction Inbound `
    -RemoteAddress 198.51.100.100 `
    -Action Block `
    -Profile Any
```

---

## 📊 What We Achieved

✅ **Firewall Enabled** - Active across all network profiles  
✅ **Default Deny Policy** - All incoming traffic blocked by default  
✅ **RDP Access Maintained** - Port 3389 allowed for remote administration  
✅ **Web Ports Open** - Ports 80/443 ready for IIS/web services (optional)  
✅ **Logging Enabled** - Security events tracked for auditing

---

## 🛡️ Security Benefits

1. **Reduced Attack Surface**: Only essential ports are exposed
2. **Protection Against Port Scans**: Unauthorized port probes are blocked
3. **Defense Against Automated Attacks**: Bots can't reach closed services
4. **Compliance Ready**: Firewall configuration required for PCI-DSS, HIPAA, SOC 2
5. **Profile-Based Security**: Different rules for Domain vs Public networks

---

## 🔐 Advanced Hardening (Optional)

### 1. Restrict RDP to Specific IPs

```powershell
# Remove default RDP rule
Remove-NetFirewallRule -DisplayName "Allow RDP (TCP-In)"

# Add restricted rule
New-NetFirewallRule -DisplayName "Allow RDP from Admin Network" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 3389 `
    -RemoteAddress 203.0.113.0/24 `
    -Action Allow `
    -Profile Any
```

---

### 2. Enable Stealth Mode (Block ICMP)

```powershell
# Disable ICMP to prevent ping responses
Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Enabled False
```

---

### 3. Block Outbound to Suspicious Ports

```powershell
# Block outbound connections to common malware C2 ports
New-NetFirewallRule -DisplayName "Block Suspicious Outbound" `
    -Direction Outbound `
    -Protocol TCP `
    -RemotePort 4444,5555,6666,7777 `
    -Action Block `
    -Profile Any
```

---

## 📖 Additional Resources

- [Microsoft:  Windows Defender Firewall with Advanced Security](https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-firewall/windows-firewall-with-advanced-security)
- [PowerShell NetSecurity Module Documentation](https://docs.microsoft.com/en-us/powershell/module/netsecurity/)
- [CIS Windows Server Hardening Benchmark](https://www.cisecurity.org/benchmark/windows_server)

---

## 🚀 Next Steps

- **Day 6+**: Consider implementing:
  - IPsec rules for encrypted traffic
  - Connection Security Rules
  - Windows Firewall with Group Policy (for multiple servers)
  - Network isolation with VLANs
  - Third-party firewall solutions (Palo Alto, Cisco ASA)

---

## 💡 Key Takeaways

> "A firewall is your server's first line of defense. Configure it early, test it thoroughly, and never expose more than you need to."

- Always allow RDP (3389) BEFORE enabling strict inbound blocking
- Use PowerShell for automation and consistency
- Default deny is the gold standard for security
- Regularly audit firewall rules with `Get-NetFirewallRule`
- Document why each rule exists

---

## 🆚 Windows vs Linux Firewall Comparison

| Feature | Windows (Defender Firewall) | Linux (UFW/iptables) |
|---------|----------------------------|---------------------|
| **Default Tool** | Windows Defender Firewall | UFW (frontend for iptables) |
| **Management** | GUI (wf.msc) or PowerShell | Command Line (ufw, iptables) |
| **Critical Port** | 3389 (RDP) | 22 (SSH) |
| **Profiles** | Domain/Private/Public | None (single ruleset) |
| **Logging** | Built-in with Event Viewer | Separate log files (/var/log) |
| **Default Policy** | Block Inbound, Allow Outbound | Block Inbound, Allow Outbound |

---

**Status:** ✅ Complete  
**Phase 1 Progress:** 5/5 Days Complete 🎉

---

## 📸 Screenshot Checklist

Document your work with these screenshots:

1. PowerShell:  `Get-NetFirewallProfile` output
2. PowerShell: `Get-NetFirewallRule` filtered output
3. GUI: Windows Defender Firewall with Advanced Security overview
4. Test:  `Test-NetConnection` results for RDP (port 3389)

Save these to your GitHub repository as proof of completion! 
