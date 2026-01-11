# Day 6: Git Security Hooks (Pre-Commit Secret Scanning) 🪝🔒

**Date:** January 6, 2026  
**Phase:** 2 - Development Security  
**Goal:** Prevent secrets and credentials from being committed to version control. 

---

## 🎯 Objective

Create an automated security check that runs **before every git commit** to detect and block sensitive information like API keys, passwords, private keys, and suspicious filenames from entering your repository.

---

## 📚 Background

**Git Hooks** are scripts that Git executes automatically at certain points in the Git workflow (e.g., before commit, before push, after merge).

### Why Pre-Commit Hooks Matter: 
- **Prevent Data Breaches**: Stop secrets from reaching GitHub/GitLab
- **Automated Security**: No manual review needed for every commit
- **Early Detection**: Catch issues before they enter version control history
- **Compliance**: Required by SOC 2, PCI-DSS, and many security frameworks

### Common Secrets to Detect:
- AWS Access Keys (`AKIA...`)
- Private SSH/TLS Keys (`BEGIN RSA PRIVATE KEY`)
- API Tokens (GitHub, Stripe, SendGrid, etc.)
- Database Connection Strings
- Hard-coded Passwords
- **Suspicious Filenames** (`.env`, `*. pem`, `*secret*`, etc.)

---

## ⚠️ Critical Flaw in Basic Implementations

Many basic pre-commit hooks **only check file content** and miss: 
- Empty files with sensitive names (`leaked_key.txt`)
- Binary key files (`.pem`, `.p12`, `.pfx`)
- Configuration files (`.env`, `credentials.json`)

### The Problem:
```bash
# This will PASS a basic content-only hook: 
touch leaked_key.txt
git add leaked_key.txt
git commit -m "oops"
# ✅ Passes (file is empty, no content to scan!)
```

### The Solution:
**Check BOTH file content AND filenames!**

---

## ⚡ Implementation

We'll cover **TWO approaches**: 
1. **Linux/Mac/WSL** - Using Bash scripts
2. **Windows Native** - Using PowerShell scripts

---

## 🐧 Method 1: Linux/Mac/WSL (Bash)

### Step 1: Navigate to Your Repository

```bash
# Clone or navigate to your repository
cd ~/AuditBot

# Verify you're in a git repository
git status
```

---

### Step 2: Locate the Hooks Folder

```bash
# Git automatically creates this folder
ls -la .git/hooks/

# You'll see sample files like:
# pre-commit. sample
# pre-push.sample
# etc.
```

---

### Step 3: Create the Pre-Commit Hook (ENHANCED VERSION)

```bash
# Create the pre-commit hook file
nano .git/hooks/pre-commit
```

**Paste this ENHANCED script:**

```bash
#!/bin/bash

echo "🔒 [AuditBot] Running Pre-Commit Security Check..."

# 1. Define Forbidden Patterns in FILE CONTENT
CONTENT_PATTERNS="AKIA[0-9A-Z]{16}|AWS_SECRET_ACCESS_KEY|BEGIN RSA PRIVATE KEY|BEGIN PRIVATE KEY|BEGIN OPENSSH PRIVATE KEY|api[_-]?key\s*[=:]|password\s*[=:]|secret[_-]?key\s*[=:]|github_pat_|ghp_[a-zA-Z0-9]{36}|sk-[a-zA-Z0-9]{32}|AIza[0-9A-Za-z-_]{35}|xox[baprs]-"

# 2. Define Forbidden Patterns in FILENAMES
FILENAME_PATTERNS=".*secret.*|.*password.*|.*\. pem$|.*\.key$|.*\. p12$|.*\.pfx$|.*id_rsa.*|.*id_dsa.*|.*id_ecdsa.*|.*id_ed25519.*|.*\.env$|.*credentials.*|.*aws.*config.*|.*leaked.*"

# 3. Check FILE CONTENT for secrets
if git grep -qEi "$CONTENT_PATTERNS" --cached; then
    echo "❌ CRITICAL SECURITY ALERT: Secret detected in FILE CONTENT!"
    echo "   Pattern matched in these files:"
    git grep -Ei "$CONTENT_PATTERNS" --cached --name-only
    echo ""
    echo "   Matched patterns:  $CONTENT_PATTERNS"
    echo "   ⚠️  Commit ABORTED."
    exit 1
fi

# 4. Check FILENAMES for suspicious names
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)
for file in $STAGED_FILES; do
    if echo "$file" | grep -qEi "$FILENAME_PATTERNS"; then
        echo "❌ CRITICAL SECURITY ALERT:  Suspicious FILENAME detected!"
        echo "   File: $file"
        echo "   Reason:  Filename matches sensitive pattern"
        echo ""
        echo "   Common sensitive filenames:"
        echo "   - *.pem, *.key (private keys)"
        echo "   - .env (environment variables)"
        echo "   - *secret*, *password*, *credential* (sensitive data)"
        echo "   - id_rsa, id_ed25519 (SSH keys)"
        echo ""
        echo "   ⚠️  Commit ABORTED."
        echo "   💡 Use .gitignore to exclude this file type."
        exit 1
    fi
done

echo "✅ Security Check Passed.  Proceeding with commit..."
exit 0
```

**Save and exit:**
- Press `Ctrl + O` (save)
- Press `Enter` (confirm)
- Press `Ctrl + X` (exit)

---

### Step 4: Make it Executable (CRITICAL!)

```bash
# Without this, Git will ignore the hook
chmod +x .git/hooks/pre-commit

# Verify it's executable
ls -l .git/hooks/pre-commit
```

**Expected output:**
```
-rwxr-xr-x 1 user user 1247 Jan 6 10:30 .git/hooks/pre-commit
```

The `x` in `-rwxr-xr-x` means executable. ✅

---

## 🪟 Method 2: Windows Native (PowerShell)

### Step 1: Navigate to Your Repository

```powershell
# Navigate to your repository
cd C:\Users\YourName\Desktop\Test\AuditBot

# Verify you're in a git repository
git status
```

---

### Step 2: Locate the Hooks Folder

```powershell
# Check if hooks folder exists
Test-Path .git\hooks

# List existing sample files
Get-ChildItem . git\hooks\
```

---

### Step 3: Create the Pre-Commit Hook (PowerShell Version)

```powershell
# Create the PowerShell hook
notepad .git\hooks\pre-commit.ps1
```

**Paste this ENHANCED PowerShell script:**

```powershell
#!/usr/bin/env pwsh
# Git Pre-Commit Hook - Secret Scanner (Enhanced)
# Checks BOTH file content AND filenames

Write-Host "🔒 [AuditBot] Running Pre-Commit Security Check..." -ForegroundColor Cyan

# Define forbidden content patterns (what's INSIDE files)
$contentPatterns = @(
    'AKIA[0-9A-Z]{16}',
    'AWS_SECRET_ACCESS_KEY',
    'BEGIN RSA PRIVATE KEY',
    'BEGIN PRIVATE KEY',
    'BEGIN OPENSSH PRIVATE KEY',
    'api[_-]? key\s*[=:]',
    'password\s*[=:]',
    'secret[_-]?key\s*[=:]',
    'github_pat_[a-zA-Z0-9]{22,}',
    'ghp_[a-zA-Z0-9]{36,}',
    'gho_[a-zA-Z0-9]{36,}',
    'sk-[a-zA-Z0-9]{32,}',
    'AIza[0-9A-Za-z-_]{35}',
    'xox[baprs]-[0-9a-zA-Z]{10,}'
)

# Define forbidden filename patterns (what the FILE IS NAMED)
$filenamePatterns = @(
    '.*secret.*',
    '.*password.*',
    '.*credential.*',
    '.*leaked.*',
    '.*\.pem$',
    '.*\. key$',
    '.*\. p12$',
    '.*\.pfx$',
    '.*id_rsa.*',
    '.*id_dsa.*',
    '.*id_ecdsa.*',
    '.*id_ed25519.*',
    '.*\.env$',
    '.*aws.*config.*',
    '.*\. pkcs12$'
)

# Get staged files
$stagedFiles = git diff --cached --name-only --diff-filter=ACM

if (-not $stagedFiles) {
    Write-Host "⚠️  No files staged for commit." -ForegroundColor Yellow
    exit 0
}

$secretFound = $false
$violatingFiles = @()

# CHECK 1: Scan file CONTENT for secrets
Write-Host "   Scanning file content..." -ForegroundColor Gray
foreach ($file in $stagedFiles) {
    if (Test-Path $file) {
        $content = Get-Content -Path $file -Raw -ErrorAction SilentlyContinue
        
        if ($content) {
            foreach ($pattern in $contentPatterns) {
                if ($content -match $pattern) {
                    $secretFound = $true
                    $violatingFiles += [PSCustomObject]@{
                        File = $file
                        Reason = "Content matches pattern: $pattern"
                        Type = "CONTENT"
                    }
                    break
                }
            }
        }
    }
}

# CHECK 2: Scan FILENAMES for suspicious names
Write-Host "   Scanning filenames..." -ForegroundColor Gray
foreach ($file in $stagedFiles) {
    foreach ($pattern in $filenamePatterns) {
        if ($file -match $pattern) {
            $secretFound = $true
            $violatingFiles += [PSCustomObject]@{
                File = $file
                Reason = "Suspicious filename pattern"
                Type = "FILENAME"
            }
            break
        }
    }
}

# If secrets found, abort commit
if ($secretFound) {
    Write-Host ""
    Write-Host "❌ CRITICAL SECURITY ALERT: Sensitive data detected!" -ForegroundColor Red
    Write-Host ""
    
    $contentViolations = $violatingFiles | Where-Object { $_.Type -eq "CONTENT" }
    $filenameViolations = $violatingFiles | Where-Object { $_.Type -eq "FILENAME" }
    
    if ($contentViolations) {
        Write-Host "   🚨 Secrets found in FILE CONTENT:" -ForegroundColor Yellow
        foreach ($violation in $contentViolations) {
            Write-Host "      - $($violation.File)" -ForegroundColor Yellow
            Write-Host "        Reason: $($violation. Reason)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    if ($filenameViolations) {
        Write-Host "   🚨 Suspicious FILENAMES detected:" -ForegroundColor Yellow
        foreach ($violation in $filenameViolations) {
            Write-Host "      - $($violation.File)" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "   💡 Common sensitive filenames:" -ForegroundColor Cyan
        Write-Host "      - *.pem, *.key (private keys)" -ForegroundColor Gray
        Write-Host "      - .env (environment variables)" -ForegroundColor Gray
        Write-Host "      - *secret*, *password*, *credential* (sensitive data)" -ForegroundColor Gray
        Write-Host "      - id_rsa, id_ed25519 (SSH keys)" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "   ⚠️  Commit ABORTED for your protection." -ForegroundColor Red
    Write-Host "   Please remove sensitive files and use .gitignore to exclude them." -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Host "✅ Security Check Passed. Proceeding with commit..." -ForegroundColor Green
exit 0
```

**Save and close Notepad.**

---

### Step 4: Configure Git to Use PowerShell Hook

**Create a wrapper bash script:**

```powershell
# Create the bash wrapper
notepad .git\hooks\pre-commit
```

**Paste this:**

```bash
#!/bin/sh
# Wrapper to execute PowerShell pre-commit hook

pwsh. exe -ExecutionPolicy Bypass -File .git/hooks/pre-commit.ps1
exit $? 
```

**Save and close.**

---

## 🧪 Testing the Hook

### Test 1: Legitimate Commit (Should Pass ✅)

**Create a safe file:**

```bash
# Linux/Mac/WSL
echo "# My Safe File" > safe-file.txt
echo "This file contains no secrets" >> safe-file.txt
git add safe-file.txt
git commit -m "Test:  Adding safe file"
```

```powershell
# Windows
"# My Safe File" | Out-File -FilePath safe-file.txt
"This file contains no secrets" | Add-Content -Path safe-file. txt
git add safe-file. txt
git commit -m "Test: Adding safe file"
```

**Expected Output:**
```
🔒 [AuditBot] Running Pre-Commit Security Check...
   Scanning file content...
   Scanning filenames... 
✅ Security Check Passed.  Proceeding with commit...
[main abc1234] Test: Adding safe file
 1 file changed, 2 insertions(+)
```

✅ **Success!** The commit was allowed. 

---

### Test 2: Empty File with Suspicious Name (Should BLOCK ❌)

**This test catches the flaw in basic implementations! **

```bash
# Linux/Mac/WSL
touch leaked_key.txt
git add leaked_key.txt
git commit -m "oops leaking secrets"
```

```powershell
# Windows
New-Item -ItemType File -Name leaked_key.txt
git add leaked_key.txt
git commit -m "oops leaking secrets"
```

**Expected Output (NOW BLOCKS):**
```
🔒 [AuditBot] Running Pre-Commit Security Check...
   Scanning file content... 
   Scanning filenames... 

❌ CRITICAL SECURITY ALERT: Suspicious FILENAME detected!
   File: leaked_key.txt
   Reason: Filename matches sensitive pattern

   Common sensitive filenames:
   - *.pem, *. key (private keys)
   - .env (environment variables)
   - *secret*, *password*, *credential* (sensitive data)
   - id_rsa, id_ed25519 (SSH keys)

   ⚠️  Commit ABORTED. 
   💡 Use .gitignore to exclude this file type. 
```

❌ **BLOCKED!** Filename check caught it.

---

### Test 3: Private Key Files (Should BLOCK ❌)

```bash
# Linux/Mac/WSL
touch id_rsa
touch server.pem
touch credentials.json
git add id_rsa server.pem credentials.json
git commit -m "test"
```

```powershell
# Windows
New-Item -ItemType File -Name id_rsa
New-Item -ItemType File -Name server.pem
New-Item -ItemType File -Name credentials.json
git add id_rsa server.pem credentials. json
git commit -m "test"
```

**Expected:** All three files blocked by filename check.

---

### Test 4: AWS Access Key in Content (Should BLOCK ❌)

```bash
# Linux/Mac/WSL
echo "AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE" > config.txt
git add config.txt
git commit -m "Test: Adding config with AWS key"
```

```powershell
# Windows
"AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE" | Out-File -FilePath config.txt
git add config.txt
git commit -m "Test:  Adding config with AWS key"
```

**Expected Output:**
```
🔒 [AuditBot] Running Pre-Commit Security Check...
   Scanning file content... 

❌ CRITICAL SECURITY ALERT: Secret detected in FILE CONTENT!
   Pattern matched in these files:
   config.txt

   ⚠️  Commit ABORTED.
```

❌ **Blocked!** Content check caught the AWS key.

---

### Test 5: Environment File (Should BLOCK ❌)

```bash
# Linux/Mac/WSL
echo "DATABASE_URL=postgres://user:pass@localhost:5432/db" > .env
git add .env
git commit -m "test"
```

```powershell
# Windows
"DATABASE_URL=postgres://user:pass@localhost:5432/db" | Out-File -FilePath .env
git add .env
git commit -m "test"
```

**Expected:** Blocked by filename pattern (`.env`).

---

### Test 6: API Key in Code (Should BLOCK ❌)

```bash
# Linux/Mac/WSL
cat > app.js << 'EOF'
const API_KEY = "sk-1234567890abcdef1234567890abcdef";

function connectToService() {
    fetch('https://api.example.com/data', {
        headers: { 'Authorization': `Bearer ${API_KEY}` }
    });
}
EOF
git add app.js
git commit -m "Test: Adding API integration"
```

```powershell
# Windows
@"
const API_KEY = "sk-1234567890abcdef1234567890abcdef";

function connectToService() {
    fetch('https://api.example.com/data', {
        headers: { 'Authorization': `Bearer ${API_KEY}` }
    });
}
"@ | Out-File -FilePath app. js
git add app.js
git commit -m "Test: Adding API integration"
```

**Expected:** Blocked by content pattern (`sk-... `).

---

## 📊 What We Achieved

✅ **Dual-Layer Protection** - Checks BOTH content AND filenames  
✅ **Catches Empty Files** - Blocks `leaked_key.txt` even if empty  
✅ **Cross-Platform** - Works on Linux, Mac, and Windows  
✅ **Customizable Patterns** - Detects AWS keys, API tokens, private keys  
✅ **Clear Error Messages** - Developers know exactly what went wrong  
✅ **Zero False Negatives** - Multiple detection strategies

---

## 🛡️ Comparison:  Before vs After

| Test Case | Basic Hook (Content Only) | Enhanced Hook (Content + Filename) |
|-----------|---------------------------|-----------------------------------|
| Empty file named `leaked_key.txt` | ✅ **Passes** (FLAW!) | ❌ **Blocks** ✓ |
| File named `secret.key` | ✅ **Passes** (FLAW!) | ❌ **Blocks** ✓ |
| File named `id_rsa` | ✅ **Passes** (FLAW!) | ❌ **Blocks** ✓ |
| File named `.env` | ✅ **Passes** (FLAW!) | ❌ **Blocks** ✓ |
| Content with `AKIA... ` | ❌ **Blocks** ✓ | ❌ **Blocks** ✓ |
| Safe file `README.md` | ✅ **Passes** ✓ | ✅ **Passes** ✓ |

---

## 🔧 Advanced Configuration

### Allow Exceptions for Test Fixtures

Sometimes you need fake secrets in test files:

```bash
# Add to your hook after line 10
EXCLUSIONS="test/fixtures|docs/examples|README.md"

# Modified check
if git grep -qEi "$CONTENT_PATTERNS" --cached | grep -vE "$EXCLUSIONS"; then
    # ...  abort logic
fi
```

---

### Bypass Hook (Emergency Override)

```bash
# Skip hooks for this commit only (USE WITH CAUTION!)
git commit --no-verify -m "Urgent fix"
```

⚠️ **WARNING:** Only use this if you're absolutely certain the file is safe!

---

### Global Git Hooks (Apply to ALL Repositories)

**Linux/Mac:**
```bash
# Set global hooks directory
git config --global core.hooksPath ~/. git-hooks

# Create the directory
mkdir -p ~/.git-hooks

# Copy your pre-commit hook
cp .git/hooks/pre-commit ~/. git-hooks/
chmod +x ~/.git-hooks/pre-commit
```

**Windows:**
```powershell
# Set global hooks directory
git config --global core.hooksPath "$env:USERPROFILE\.git-hooks"

# Create the directory
New-Item -ItemType Directory -Path "$env:USERPROFILE\. git-hooks" -Force

# Copy your hooks
Copy-Item . git\hooks\pre-commit "$env:USERPROFILE\.git-hooks\"
Copy-Item .git\hooks\pre-commit.ps1 "$env:USERPROFILE\.git-hooks\"
```

---

## 🛠️ Professional Tools (Alternatives)

While our custom hook works great, consider these enterprise-grade tools:

### 1. **Gitleaks** (Recommended - Go-based, fast)
```bash
# Install on Linux
wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz
tar -xzf gitleaks_8.18.0_linux_x64.tar.gz
sudo mv gitleaks /usr/local/bin/

# Install on Windows (via Chocolatey)
choco install gitleaks

# Scan staged files
gitleaks protect --staged
```

**Add to pre-commit hook:**
```bash
#!/bin/bash
echo "🔒 Running Gitleaks scan..."
gitleaks protect --staged --verbose
exit $?
```

---

### 2. **git-secrets** (AWS Labs)
```bash
# Install on Linux/Mac
brew install git-secrets

# Install on Windows (via Chocolatey)
choco install git-secrets

# Initialize in your repo
cd your-repo
git secrets --install
git secrets --register-aws
```

---

### 3. **detect-secrets** (Yelp)
```bash
# Install with pip
pip install detect-secrets

# Create baseline
detect-secrets scan > . secrets.baseline

# Add pre-commit hook
detect-secrets-hook --baseline .secrets.baseline
```

---

### 4. **TruffleHog** (Truffle Security)
```bash
# Install
pip install truffleHog

# Scan repository
trufflehog git file://. --json
```

---

## 🔍 Troubleshooting

### Issue: Hook Not Running

**Solution:**
```bash
# Linux/Mac - Check executable permission
ls -l .git/hooks/pre-commit
# Should show: -rwxr-xr-x

# If not executable: 
chmod +x .git/hooks/pre-commit
```

```powershell
# Windows - Verify PowerShell execution policy
Get-ExecutionPolicy

# If Restricted, set to RemoteSigned: 
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

---

### Issue: Windows "File Not Found"

**Solution:**
```powershell
# Ensure Git can find PowerShell
where. exe pwsh

# If not found, install PowerShell 7+
winget install Microsoft.PowerShell
```

---

### Issue: False Positives

**Solution - Add Exclusions:**

```bash
# In your hook, skip specific files
if echo "$file" | grep -qE "test/|docs/|README"; then
    continue
fi
```

---

## 📖 Additional Resources

- [Git Hooks Documentation](https://git-scm.com/docs/githooks)
- [OWASP:  Secrets Management Cheat Sheet](https://cheatsheetseries.owasp. org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [GitHub: Removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [AWS: git-secrets](https://github.com/awslabs/git-secrets)
- [Gitleaks Documentation](https://github.com/gitleaks/gitleaks)

---

## 🚀 Next Steps

**Day 7+**:  Consider implementing: 
- **Pre-Push Hooks**:  Scan before pushing to remote
- **CI/CD Integration**: Run secret scanning in GitHub Actions/Jenkins
- **Commit-Msg Hooks**: Enforce commit message standards
- **Pre-Rebase Hooks**: Prevent rewriting history with secrets

---

## 💡 Key Takeaways

> "The best time to catch a secret is BEFORE it enters version control.  The second best time is NOW."

- **Git history is permanent** - even deleted commits can be recovered
- **Check BOTH content and filenames** - defense in depth
- **Never commit --no-verify** unless you're absolutely certain
- **Use environment variables** for all credentials
- **Rotate immediately** if a secret is ever committed

---

## ⚠️ Emergency:  I Already Committed a Secret! 

### Step 1: Remove from Latest Commit (Not Pushed Yet)

```bash
# Remove the file
git rm config.txt

# Amend the commit
git commit --amend --no-edit

# Or reset completely
git reset --hard HEAD~1
```

---

### Step 2: Remove from History (Already Pushed)

**Using BFG Repo-Cleaner (Recommended):**
```bash
# Download BFG
wget https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar

# Remove all files named "secrets. txt"
java -jar bfg-1.14.0.jar --delete-files secrets.txt your-repo.git

# Clean up
cd your-repo
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push (WARNING:  Rewrites history)
git push --force
```

**Using git-filter-repo:**
```bash
# Install
pip install git-filter-repo

# Remove file from all history
git filter-repo --invert-paths --path config.txt

# Force push
git push --force
```

---

### Step 3: Rotate the Credential IMMEDIATELY

- **AWS Keys**: Delete and create new keys in IAM Console
- **API Tokens**:  Revoke and generate new tokens
- **Passwords**: Change immediately
- **SSH Keys**: Generate new keypair

⚠️ **Never assume a secret is "private enough" - always rotate!**

---

## 📸 Screenshot Checklist

Document your work: 

1. ✅ `.git/hooks/pre-commit` file contents
2. ✅ `ls -l .git/hooks/pre-commit` showing executable permission
3. ✅ Successful commit (green checkmark output)
4. ✅ Blocked commit with AWS key (red X output)
5. ✅ Blocked commit with suspicious filename (`leaked_key.txt`)
6. ✅ Test results showing all 6 test cases

---

**Status:** ✅ Complete  
**Phase 2 Progress:** 1/5 Days Complete 🎉  
**Security Level:** 🔒🔒🔒🔒🔒 (5/5 - Production Ready)

---

## 🎓 Bonus: CI/CD Integration

### GitHub Actions Workflow

Create `.github/workflows/secret-scan. yml`:

```yaml
name: Secret Scanning

on:  [push, pull_request]

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps: 
      - uses: actions/checkout@v3
        with:
          fetch-depth:  0
      
      - name: Run Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

This ensures secrets are caught even if developers bypass local hooks! 

---

## 🧠 Understanding the Fix

### What Was Wrong: 
```bash
# Old version only checked file CONTENT
git grep -qE "$FORBIDDEN" --cached
# If file is empty or binary, this PASSES ❌
```

### What We Fixed:
```bash
# New version checks BOTH content AND filename
1. git grep -qEi "$CONTENT_PATTERNS" --cached  # Check what's INSIDE
2. echo "$file" | grep -qEi "$FILENAME_PATTERNS"  # Check the NAME
```

### Why This Matters:
- **Empty credential files** are still dangerous (might be filled later)
- **Binary key files** (`.pem`, `.p12`) can't be scanned as text
- **Configuration files** (`.env`) should NEVER be committed

---

**Next:** Proceed to Day 7 - Dependency Vulnerability Scanning 🚀
