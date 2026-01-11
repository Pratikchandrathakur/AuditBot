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
- AWS Access Keys (`AKIA... `)
- Private SSH/TLS Keys (`BEGIN RSA PRIVATE KEY`)
- API Tokens (GitHub, Stripe, SendGrid, etc.)
- Database Connection Strings
- Hard-coded Passwords
- **Suspicious Filenames** (`.env`, `*. pem`, `*secret*`, etc.)

---

## ⚠️ Critical Requirement:  Two-Layer Defense

A robust pre-commit hook must check **TWO things**: 

1. **File Content** - What's INSIDE the file (AWS keys, passwords, etc.)
2. **Filenames** - What the file is NAMED (`.env`, `secret. key`, `leaked_key.txt`, etc.)

### Why Both Matter:
- Empty files with dangerous names like `leaked_key.txt` are still security risks
- Binary key files (`.pem`, `.p12`) can't always be scanned as text
- Configuration files (`.env`) should NEVER be committed regardless of content

---

## ⚡ Implementation

We'll cover **TWO approaches**: 
1. **Linux/Mac/WSL/Git Bash** - Using Bash scripts
2. **Windows Native** - Using PowerShell scripts

---

## 🐧 Method 1: Linux/Mac/WSL/Git Bash (Enhanced Version)

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

### Step 3: Create the Pre-Commit Hook

```bash
# Create the pre-commit hook file
nano .git/hooks/pre-commit
```

**Paste this ENHANCED script:**

```bash
#!/bin/bash

echo "🔒 [AuditBot] Running Pre-Commit Security Check..."

# 1. Define Forbidden Patterns in FILE CONTENT
FORBIDDEN="AKIA[0-9A-Z]{16}|AWS_SECRET_ACCESS_KEY|aws_secret_access_key|BEGIN RSA PRIVATE KEY|BEGIN PRIVATE KEY|BEGIN OPENSSH PRIVATE KEY|api[_-]? key|password\s*=|secret[_-]?key|github_pat_|ghp_[a-zA-Z0-9]{36}|sk-[a-zA-Z0-9]{32}|bearer\s|private[_-]?key"

# 2. Define Forbidden Patterns in FILENAMES
FILENAME_FORBIDDEN="secret|password|credential|leaked|\. pem$|\.key$|\.p12$|\. pfx$|id_rsa|id_dsa|id_ecdsa|id_ed25519|\. env$|aws.*config"

# 3. Check FILE CONTENT for secrets using git grep
# --cached = look at staged files
# -E = extended regex
# -i = case insensitive
# -q = quiet mode (just return exit code)
if git grep --cached -qEi "$FORBIDDEN"; then
    echo "❌ CRITICAL SECURITY ALERT: Secret detected in FILE CONTENT!"
    echo "   You are trying to commit a sensitive key or credential."
    echo ""
    echo "   Files containing secrets:"
    git grep --cached -Eli "$FORBIDDEN" --name-only
    echo ""
    echo "   Pattern matched: $FORBIDDEN"
    echo "   ⚠️  Commit ABORTED."
    exit 1
fi

# 4. Check FILENAMES for suspicious patterns
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

for file in $STAGED_FILES; do
    if echo "$file" | grep -qEi "$FILENAME_FORBIDDEN"; then
        echo "❌ CRITICAL SECURITY ALERT:  Suspicious FILENAME detected!"
        echo "   File: $file"
        echo "   Reason:  Filename matches sensitive pattern"
        echo ""
        echo "   Common sensitive filenames:"
        echo "   - *.pem, *.key (private keys)"
        echo "   - . env (environment variables)"
        echo "   - *secret*, *password*, *credential* (sensitive data)"
        echo "   - id_rsa, id_ed25519 (SSH keys)"
        echo ""
        echo "   ⚠️  Commit ABORTED."
        echo "   💡 Use . gitignore to exclude this file type."
        exit 1
    fi
done

echo "✅ Security Check Passed. Proceeding with commit..."
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
-rwxr-xr-x 1 user user 1450 Jan 6 10:30 .git/hooks/pre-commit
```

The `x` in `-rwxr-xr-x` means executable.  ✅

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

### Step 2: Create the PowerShell Hook

```powershell
# Create the PowerShell hook
notepad .git\hooks\pre-commit.ps1
```

**Paste this PowerShell script:**

```powershell
#!/usr/bin/env pwsh
# Git Pre-Commit Hook - Secret Scanner

Write-Host "🔒 [AuditBot] Running Pre-Commit Security Check..." -ForegroundColor Cyan

# Define forbidden content patterns
$contentPatterns = @(
    'AKIA',
    'AWS_SECRET_ACCESS_KEY',
    'aws_secret_access_key',
    'BEGIN RSA PRIVATE KEY',
    'BEGIN PRIVATE KEY',
    'BEGIN OPENSSH PRIVATE KEY',
    'api_key',
    'apikey',
    'password\s*=',
    'secret\s*=',
    'github_pat_',
    'ghp_',
    'sk-',
    'bearer ',
    'private_key',
    '-----BEGIN'
)

# Define forbidden filename patterns
$filenamePatterns = @(
    'secret',
    'password',
    'credential',
    'leaked',
    '.pem',
    '.key',
    '.p12',
    '.pfx',
    'id_rsa',
    'id_dsa',
    'id_ecdsa',
    'id_ed25519',
    '.env',
    'aws.*config'
)

# Get staged files
$stagedFiles = git diff --cached --name-only --diff-filter=ACM

if (-not $stagedFiles) {
    Write-Host "⚠️  No files staged for commit." -ForegroundColor Yellow
    exit 0
}

Write-Host "   📂 Checking $(@($stagedFiles).Count) file(s)..." -ForegroundColor Gray

$violationsFound = $false
$contentViolations = @()
$filenameViolations = @()

# Check each staged file
foreach ($file in $stagedFiles) {
    Write-Host "   🔍 Scanning: $file" -ForegroundColor DarkGray
    
    if (-not (Test-Path $file)) {
        continue
    }
    
    # CHECK 1: Scan FILENAME
    foreach ($pattern in $filenamePatterns) {
        if ($file -like "*$pattern*") {
            Write-Host "      ❌ FILENAME VIOLATION: Contains '$pattern'" -ForegroundColor Red
            $violationsFound = $true
            $filenameViolations += $file
            break
        }
    }
    
    # CHECK 2: Scan FILE CONTENT
    try {
        $content = Get-Content -Path $file -Raw -ErrorAction Stop
        
        if ($content) {
            foreach ($pattern in $contentPatterns) {
                if ($content -match "(? i)$pattern") {
                    Write-Host "      ❌ CONTENT VIOLATION: Found '$pattern'" -ForegroundColor Red
                    $violationsFound = $true
                    $contentViolations += [PSCustomObject]@{
                        File = $file
                        Pattern = $pattern
                    }
                    break
                }
            }
        }
    }
    catch {
        Write-Host "      ⚠️  Could not read file (binary? ): $file" -ForegroundColor DarkYellow
    }
}

# Report violations
if ($violationsFound) {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host "❌ CRITICAL SECURITY ALERT:  Sensitive data detected!" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host ""
    
    if ($filenameViolations. Count -gt 0) {
        Write-Host "   🚨 Suspicious FILENAMES:" -ForegroundColor Yellow
        foreach ($file in ($filenameViolations | Select-Object -Unique)) {
            Write-Host "      • $file" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    if ($contentViolations.Count -gt 0) {
        Write-Host "   🚨 Secrets found in FILE CONTENT:" -ForegroundColor Yellow
        foreach ($violation in $contentViolations) {
            Write-Host "      • File: $($violation.File)" -ForegroundColor Yellow
            Write-Host "        Pattern: $($violation.Pattern)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    Write-Host "   💡 What to do:" -ForegroundColor Cyan
    Write-Host "      1. Remove the secret from the file" -ForegroundColor White
    Write-Host "      2. Use environment variables instead" -ForegroundColor White
    Write-Host "      3. Add the file to .gitignore if needed" -ForegroundColor White
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host "⚠️  COMMIT ABORTED FOR YOUR PROTECTION" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host ""
    
    exit 1
}

Write-Host "✅ Security Check Passed. Proceeding with commit..." -ForegroundColor Green
exit 0
```

**Save and close Notepad.**

---

### Step 3: Create Bash Wrapper (Required for Git)

```powershell
# Create the bash wrapper
notepad .git\hooks\pre-commit
```

**Paste this:**

```bash
#!/bin/sh
# Wrapper to execute PowerShell pre-commit hook

echo "🔍 Launching PowerShell security scanner..."

pwsh. exe -ExecutionPolicy Bypass -NoProfile -File ". git/hooks/pre-commit. ps1"

# Capture and return the exit code
EXIT_CODE=$? 
exit $EXIT_CODE
```

**Save and close.**

---

## 🧪 Testing the Hook

### Test 1: Legitimate Commit (Should Pass ✅)

```bash
# Linux/Mac/WSL
echo "# My Safe File" > README.md
echo "This file contains no secrets" >> README.md
git add README.md
git commit -m "Test:  Adding safe file"
```

```powershell
# Windows
"# My Safe File" | Out-File -FilePath README.md
"This file contains no secrets" | Add-Content -Path README.md
git add README.md
git commit -m "Test: Adding safe file"
```

**Expected Output:**
```
🔒 [AuditBot] Running Pre-Commit Security Check...
✅ Security Check Passed. Proceeding with commit... 
[main abc1234] Test: Adding safe file
 1 file changed, 2 insertions(+)
```

✅ **Success!**

---

### Test 2: Secret Hidden in Innocent Filename (Should BLOCK ❌)

**This is the critical test that catches hidden secrets! **

```bash
# Linux/Mac/WSL
echo "AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE" > help.txt
echo "Some helpful documentation here..." >> help.txt
git add help.txt
git commit -m "Adding help documentation"
```

```powershell
# Windows
"AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE" | Out-File -FilePath help.txt
"Some helpful documentation here..." | Add-Content -Path help.txt
git add help. txt
git commit -m "Adding help documentation"
```

**Expected Output:**
```
🔒 [AuditBot] Running Pre-Commit Security Check... 
❌ CRITICAL SECURITY ALERT: Secret detected in FILE CONTENT!
   You are trying to commit a sensitive key or credential. 

   Files containing secrets:
   help.txt

   Pattern matched: AKIA[0-9A-Z]{16}|AWS_SECRET_ACCESS_KEY|... 
   ⚠️  Commit ABORTED. 
```

❌ **BLOCKED! ** The hook caught the AWS key inside `help.txt`.

---

### Test 3: Empty File with Suspicious Name (Should BLOCK ❌)

```bash
# Linux/Mac/WSL
touch leaked_key.txt
git add leaked_key.txt
git commit -m "test"
```

```powershell
# Windows
New-Item -ItemType File -Name leaked_key.txt
git add leaked_key.txt
git commit -m "test"
```

**Expected Output:**
```
🔒 [AuditBot] Running Pre-Commit Security Check... 
❌ CRITICAL SECURITY ALERT: Suspicious FILENAME detected!
   File: leaked_key.txt
   Reason: Filename matches sensitive pattern

   Common sensitive filenames:
   - *.pem, *. key (private keys)
   - .env (environment variables)
   - *secret*, *password*, *credential* (sensitive data)

   ⚠️  Commit ABORTED.
```

❌ **BLOCKED!** Caught by filename check.

---

### Test 4: Private Key File (Should BLOCK ❌)

```bash
# Linux/Mac/WSL
cat > server.pem << 'EOF'
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1234567890
-----END RSA PRIVATE KEY-----
EOF
git add server.pem
git commit -m "test"
```

```powershell
# Windows
@"
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1234567890
-----END RSA PRIVATE KEY-----
"@ | Out-File -FilePath server.pem
git add server.pem
git commit -m "test"
```

**Expected:** Blocked by BOTH filename (`.pem`) AND content (`BEGIN RSA PRIVATE KEY`).

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

### Test 6: Password in Code (Should BLOCK ❌)

```bash
# Linux/Mac/WSL
cat > config.js << 'EOF'
const dbPassword = "MySecretPassword123";
const config = {
  password: "SuperSecret",
  user: "admin"
};
EOF
git add config.js
git commit -m "test"
```

```powershell
# Windows
@"
const dbPassword = "MySecretPassword123";
const config = {
  password: "SuperSecret",
  user: "admin"
};
"@ | Out-File -FilePath config.js
git add config.js
git commit -m "test"
```

**Expected:** Blocked by content pattern (`password\s*=`).

---

## 📊 What We Achieved

✅ **Dual-Layer Protection** - Checks BOTH content AND filenames  
✅ **Catches Hidden Secrets** - Blocks `help.txt` with AWS keys inside  
✅ **Catches Empty Dangerous Files** - Blocks `leaked_key.txt` even if empty  
✅ **Cross-Platform** - Works on Linux, Mac, and Windows  
✅ **Comprehensive Patterns** - Detects AWS keys, API tokens, private keys, passwords  
✅ **Clear Error Messages** - Developers know exactly what went wrong  
✅ **Git Grep Efficiency** - Uses Git's built-in search for content  
✅ **Filename Validation** - Explicit check for dangerous file names

---

## 🛡️ How It Works

### Two-Stage Detection: 

**Stage 1: Content Check (Using `git grep`)**
```bash
git grep --cached -qEi "$FORBIDDEN"
```
- `--cached`: Only check staged files (about to be committed)
- `-q`: Quiet mode (just return yes/no)
- `-E`: Extended regex support
- `-i`: Case insensitive

**Stage 2: Filename Check (Using `grep` on filenames)**
```bash
echo "$file" | grep -qEi "$FILENAME_FORBIDDEN"
```
- Checks each staged filename against dangerous patterns
- Catches `.env`, `*.pem`, `*secret*`, `*password*`, etc.

---

## 🔧 Customization

### Add More Content Patterns

Edit the `FORBIDDEN` variable: 

```bash
# Add API key patterns for specific services
FORBIDDEN="AKIA[0-9A-Z]{16}|AWS_SECRET_ACCESS_KEY|.. .|stripe_[a-z_]+_[A-Za-z0-9]{32}|firebase_key"
```

### Add More Filename Patterns

Edit the `FILENAME_FORBIDDEN` variable:

```bash
# Add company-specific patterns
FILENAME_FORBIDDEN="secret|password|.. .|mycompany_private|internal_key"
```

### Add Exceptions (Whitelist)

```bash
# Add after the STAGED_FILES line
EXCEPTIONS="test/fixtures|docs/examples|README.md"

for file in $STAGED_FILES; do
    # Skip whitelisted paths
    if echo "$file" | grep -qE "$EXCEPTIONS"; then
        continue
    fi
    
    # ...  rest of filename checking
done
```

---

## 🔍 Troubleshooting

### Issue: Hook Not Running

**Linux/Mac:**
```bash
# Check executable permission
ls -l .git/hooks/pre-commit
# Should show:  -rwxr-xr-x

# If not executable: 
chmod +x .git/hooks/pre-commit
```

**Windows:**
```powershell
# Check PowerShell is available
where. exe pwsh

# If not found:
winget install Microsoft.PowerShell

# Check execution policy
Get-ExecutionPolicy

# If Restricted:
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

---

### Issue: Hook Passes When It Should Block

**Debug the hook:**

```bash
# Test git grep directly
git add your-file.txt
git grep --cached -Ei "AKIA"

# If it finds the pattern, it will show you the line
# If it returns nothing, the pattern needs adjustment
```

---

### Issue: False Positives

**Add exclusions:**

```bash
# Skip certain file types
if echo "$file" | grep -qE "\.md$|\.txt$|test/"; then
    continue
fi
```

---

## 🛠️ Professional Alternatives

### 1. **Gitleaks** (Recommended)

```bash
# Install
brew install gitleaks  # Mac
choco install gitleaks  # Windows

# Replace your pre-commit with: 
#!/bin/bash
gitleaks protect --staged --verbose
exit $?
```

### 2. **git-secrets** (AWS Labs)

```bash
# Install
brew install git-secrets

# Setup in repo
git secrets --install
git secrets --register-aws
```

### 3. **detect-secrets** (Yelp)

```bash
pip install detect-secrets
detect-secrets scan > . secrets.baseline
detect-secrets-hook --baseline .secrets.baseline
```

---

## 🚀 Advanced Configuration

### Bypass Hook (Emergency Only)

```bash
# Skip hooks for this commit (USE WITH EXTREME CAUTION!)
git commit --no-verify -m "Urgent hotfix"
```

⚠️ **WARNING:** Only use when absolutely necessary!

---

### Global Hooks (Apply to ALL Repositories)

**Linux/Mac:**
```bash
# Set global hooks directory
git config --global core.hooksPath ~/. git-hooks

# Create directory
mkdir -p ~/.git-hooks

# Copy hook
cp .git/hooks/pre-commit ~/.git-hooks/
chmod +x ~/.git-hooks/pre-commit
```

**Windows:**
```powershell
git config --global core.hooksPath "$env:USERPROFILE\.git-hooks"
New-Item -ItemType Directory -Path "$env:USERPROFILE\. git-hooks" -Force
Copy-Item .git\hooks\pre-commit "$env:USERPROFILE\.git-hooks\"
Copy-Item .git\hooks\pre-commit.ps1 "$env:USERPROFILE\.git-hooks\"
```

---

### CI/CD Integration (GitHub Actions)

Create `.github/workflows/secret-scan.yml`:

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
          GITHUB_TOKEN:  ${{ secrets.GITHUB_TOKEN }}
```

This catches secrets even if developers bypass local hooks!

---

## 💡 Key Takeaways

> "The best time to catch a secret is BEFORE it enters version control.  The second best time is NOW."

- **Check BOTH content and filenames** - defense in depth
- **Git grep is efficient** - uses Git's index for fast searching
- **Filename checks catch edge cases** - empty files, binary files
- **Never use `--no-verify`** unless absolutely certain
- **Use environment variables** for all credentials
- **Rotate immediately** if a secret is ever committed

---

## ⚠️ Emergency:  I Already Committed a Secret! 

### Step 1: Remove from Latest Commit (Not Pushed)

```bash
# Remove the file
git rm help.txt

# Amend the commit
git commit --amend --no-edit

# Or reset completely
git reset --hard HEAD~1
```

---

### Step 2: Remove from History (Already Pushed)

**Using BFG Repo-Cleaner:**
```bash
# Download BFG
wget https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar

# Remove file
java -jar bfg-1.14.0.jar --delete-files help.txt

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push (WARNING:  Rewrites history)
git push --force
```

**Using git-filter-repo:**
```bash
pip install git-filter-repo
git filter-repo --invert-paths --path help.txt
git push --force
```

---

### Step 3: Rotate Credentials IMMEDIATELY

- **AWS Keys**: Delete in IAM Console, create new keys
- **API Tokens**:  Revoke and regenerate
- **Passwords**: Change immediately
- **SSH Keys**: Generate new keypair

⚠️ **Never assume a leaked secret is "safe enough" - always rotate!**

---

## 📖 Additional Resources

- [Git Hooks Documentation](https://git-scm.com/docs/githooks)
- [OWASP:  Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [GitHub:  Removing Sensitive Data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [Gitleaks Documentation](https://github.com/gitleaks/gitleaks)
- [AWS git-secrets](https://github.com/awslabs/git-secrets)

---

## 📸 Screenshot Checklist

Document your work: 

1. ✅ `.git/hooks/pre-commit` file contents
2. ✅ `ls -l .git/hooks/pre-commit` showing `-rwxr-xr-x`
3. ✅ Successful commit with safe file (green checkmark)
4. ✅ Blocked commit with AWS key in `help.txt` (red X)
5. ✅ Blocked commit with suspicious filename `leaked_key.txt`
6. ✅ All 6 test cases passing/blocking correctly

---

**Status:** ✅ Complete  
**Phase 2 Progress:** 1/5 Days Complete 🎉  
**Security Level:** 🔒🔒🔒🔒🔒 (5/5 - Production Ready)

---

## 🎓 Bonus: Understanding the Logic

### Why `git grep --cached` is Powerful: 

```bash
# This command: 
git grep --cached -qEi "AKIA"

# Is equivalent to:
# 1. Get all staged files
# 2. For each file, read its content from Git's staging area
# 3. Search for the pattern "AKIA"
# 4. Return exit code 0 if found, 1 if not found
```

**Benefits:**
- ✅ Fast (uses Git's index)
- ✅ Only checks staged files
- ✅ Works with large repositories
- ✅ Supports full regex

### Why We Also Check Filenames:

```bash
# Scenario:  Empty file named "secret.key"
touch secret.key
git add secret. key

# git grep returns NOTHING (file is empty)
# Filename check catches it! 
```

**This is the defense-in-depth approach! **

---

**Next:** Proceed to Day 7 - Dependency Vulnerability Scanning 🚀
