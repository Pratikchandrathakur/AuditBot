# Day 5: Firewalls (UFW/IPTables) 🔥🛡️

**Date:** January 5, 2026  
**Phase:** 1 - Foundation  
**Goal:** Block all doors except the one you watch. 

---

## 🎯 Objective

Lock down server networking to ignore all traffic except SSH (and optionally HTTP/HTTPS for web services). This ensures that only authorized services are accessible from the outside world and make sure you have used the ssh configurations as in the config and ssh should be hardened as well.

---

## 📚 Background

**UFW (Uncomplicated Firewall)** is a user-friendly frontend for managing iptables firewall rules on Ubuntu/Debian systems. It provides a simple command-line interface for configuring network access rules.

### Why Firewalls Matter: 
- **Defense in Depth**: Even if a service has a vulnerability, the firewall can prevent unauthorized access
- **Attack Surface Reduction**: Only expose the ports you actually need
- **Default Deny**: Block everything by default, then explicitly allow what's necessary

---

## ⚡ Implementation Steps

### 1. Install & Set Defaults (The Base)

First, install UFW and configure the default policies:

```bash
# Update package list and install UFW
sudo apt update && sudo apt install ufw -y

# Deny all incoming traffic by default
sudo ufw default deny incoming

# Allow all outgoing traffic by default
sudo ufw default allow outgoing
```

**What this does:**
- `deny incoming`: Blocks all inbound connections unless explicitly allowed
- `allow outgoing`: Permits the server to initiate connections to the internet (for updates, etc.)

---

### 2. The Lifeline (CRITICAL ⚠️)

**WARNING:** If you skip this step, you WILL lock yourself out via SSH! 

```bash
# Allow SSH connections (Port 22)
sudo ufw allow 22/tcp

# Optional: Allow web traffic if hosting websites
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
```

**Why this matters:**
- Port 22 is required for SSH access
- Without this rule, enabling UFW will block your SSH connection
- Ports 80/443 are safe to add now if you plan to host web services later

---

### 3. Activate the Shield

Enable the firewall:

```bash
sudo ufw enable
```

You'll see a warning: 
```
Command may disrupt existing ssh connections.  Proceed with operation (y|n)?
```

Type `y` and press Enter to confirm.

**Output:**
```
Firewall is active and enabled on system startup
```

---

### 4. Verification (Proof of Work)

Check the firewall status:

```bash
sudo ufw status verbose
```

**Expected Output:**
```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
80/tcp                     ALLOW IN    Anywhere
443/tcp                    ALLOW IN    Anywhere
22/tcp (v6)                ALLOW IN    Anywhere (v6)
80/tcp (v6)                ALLOW IN    Anywhere (v6)
443/tcp (v6)               ALLOW IN    Anywhere (v6)
```

---

## 🧪 Testing the Firewall

### Test ICMP (Ping) Blocking

From another machine, try to ping your server:

```bash
ping your-server-ip
```

**Result:** The ping should be blocked (no response or filtered), confirming that unwanted traffic is being dropped.

### Test SSH Access

Verify you can still SSH into your server:

```bash
ssh user@your-server-ip
```

**Result:** Connection should work normally since port 22 is allowed.

---

## 🔍 Understanding UFW Rules

### Common UFW Commands

```bash
# View status
sudo ufw status

# View status with rule numbers
sudo ufw status numbered

# Allow a specific port
sudo ufw allow <port>/<protocol>

# Deny a specific port
sudo ufw deny <port>/<protocol>

# Delete a rule by number
sudo ufw delete <number>

# Disable firewall
sudo ufw disable

# Reset to default (removes all rules)
sudo ufw reset
```

---

## 📊 What We Achieved

✅ **UFW Enabled** - Firewall is active and starts on boot  
✅ **Default Deny Policy** - All incoming traffic blocked by default  
✅ **SSH Access Maintained** - Port 22 allowed for remote administration  
✅ **Web Ports Open** - Ports 80/443 ready for future web services  
✅ **ICMP Filtering** - Ping requests blocked (optional security through obscurity)

---

## 🛡️ Security Benefits

1. **Reduced Attack Surface**: Only essential ports are exposed
2. **Protection Against Port Scans**: Unauthorized port probes are blocked
3. **Defense Against Automated Attacks**: Bots can't reach closed services
4. **Compliance Ready**: Firewall configuration is a requirement for many security standards

---

## 📖 Additional Resources

- [Ubuntu UFW Documentation](https://help.ubuntu.com/community/UFW)
- [DigitalOcean UFW Essentials](https://www.digitalocean.com/community/tutorials/ufw-essentials-common-firewall-rules-and-commands)
- [IPTables Documentation](https://www.netfilter.org/documentation/)

---

## 🚀 Next Steps

- **Day 6+**: Consider implementing: 
  - Application-specific firewall rules
  - Rate limiting with UFW
  - IPv6 firewall rules
  - Advanced iptables configurations
  - Network segmentation

---

## 💡 Key Takeaways

> "A firewall is your server's first line of defense. Configure it early, test it thoroughly, and never expose more than you need to."

- Always allow SSH BEFORE enabling the firewall
- Default deny is the gold standard for security
- Regularly audit your firewall rules
- Document why each rule exists

---

**Status:** ✅ Complete  
**Phase 1 Progress:** 5/5 Days Complete 🎉
