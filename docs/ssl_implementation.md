# 🔐 Engineering Log:  TLS/HTTPS Implementation Strategy

**Date:** 2026-01-12  
**Component:** Secure Web Server (Phase 1)  
**Security Domain:** Data in Transit Protection  
**Engineer:** [Your Name]

---

## 1. Executive Summary

To mitigate **Man-in-the-Middle (MitM)** attacks and ensure confidentiality, we have implemented TLS 1.3 encryption for the web server component. This Proof of Concept (PoC) utilizes **Self-Signed Certificates** to demonstrate the cryptographic handshake mechanism.

**Key Risk Addressed:**
- **Cleartext Interception:** HTTP sends data (passwords/API keys) in plain text
- **Protocol Downgrade:** Prevents attackers from forcing an insecure connection
- **Session Hijacking:** Encrypted sessions cannot be stolen via packet sniffing

**Status:** ✅ Proof of Concept Complete

---

## 2. Technical Implementation

### A. Certificate Generation (OpenSSL)

We act as our own **Certificate Authority (CA)**.  This allows us to generate a key pair without external costs, suitable for internal testing or development environments.

```bash
# 1. Generate Private Key (The Secret) - RSA 2048 bit
# SECURITY NOTE: In production, this key must be stored in a Vault (e.g., AWS Secrets Manager).
openssl genrsa -out server.key 2048

# 2. Generate Public Certificate (The Identity)
# This is the "ID Card" presented to clients. 
openssl req -new -x509 -key server.key -out server.crt -days 365
```

**Key Characteristics:**
- **Algorithm:** RSA 2048-bit
- **Validity:** 365 days
- **Subject:** CN=localhost
- **Self-Signed:** Yes (Issuer = Subject)

---

### B. Python Server Configuration

The Python `ssl` module is used to wrap the standard TCP socket.  This enforces encryption before any application data is exchanged.

**Code Snippet:**
```python
import ssl
import http.server

# Create SSL context (TLS 1.2 minimum, prefers TLS 1.3)
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain(certfile="certs/server.crt", keyfile="certs/server.key")

# Create HTTP server
httpd = http.server.HTTPServer(('localhost', 8000), RequestHandler)

# Wrap socket with SSL
httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

# Start serving
httpd.serve_forever()
```

**Security Features:**
- ✅ **TLS 1.3 Support:** Modern protocol with forward secrecy
- ✅ **Strong Cipher Suites:** AES-256-GCM, ChaCha20-Poly1305
- ✅ **Perfect Forward Secrecy:** Ephemeral keys (ECDHE)

---

## 3. Verification & Evidence

### Browser Validation

Upon accessing `https://localhost:8000`, the browser triggers a **Security Warning**. 

**Why this happens (The Chain of Trust):**

| Aspect | Status | Explanation |
|--------|--------|-------------|
| **Encryption** | ✅ **YES** | The connection IS encrypted.  Data cannot be sniffed. |
| **Identity** | ❌ **NO** | The browser does not trust the Issuer (Us). It expects a root CA (like DigiCert or Let's Encrypt). |

**Evidence:**

![Browser Warning Screenshot](./screenshots/day7-browser-warning.png)
*Browser shows "Not Secure" but connection is encrypted*

![Certificate Details](./screenshots/day7-certificate-details.png)
*Self-signed certificate details showing RSA 2048-bit encryption*

---

### Wireshark Packet Analysis

**Test Setup:**
1.  Capture traffic on loopback interface (127.0.0.1)
2. Filter: `tcp.port == 8000`
3. Access HTTPS server

**Results:**
```
TLSv1.3 Handshake: 
- Client Hello (cipher suites)
- Server Hello (selected cipher:  TLS_AES_256_GCM_SHA384)
- Certificate (self-signed)
- Encrypted Application Data ✅
```

**Observation:** All HTTP content is encrypted.  Packet payload shows random bytes, not readable text.

![Wireshark Encrypted Traffic](./screenshots/day7-wireshark-encrypted.png)

---

## 4. Enterprise Application Note

In a **production environment** (Real Enterprise), we would NOT use manual self-signed certs. 

### Production Architecture: 

| Environment | Solution | Trust Model |
|-------------|----------|-------------|
| **Public Facing** | Let's Encrypt / AWS ACM | Trusted by all browsers |
| **Internal (Microservices)** | HashiCorp Vault / Internal PKI | Trusted within organization |
| **API Gateway** | Cloudflare / AWS CloudFront | Managed TLS termination |
| **Zero Trust** | Mutual TLS (mTLS) | Both client AND server authenticate |

### Recommended Tools:

1. **Let's Encrypt** (Free, Automated)
   ```bash
   certbot certonly --standalone -d example.com
   ```

2. **AWS Certificate Manager** (Managed)
   - Automatic renewal
   - Integrated with ALB/CloudFront
   - No certificate file management

3. **HashiCorp Vault PKI**
   ```bash
   vault write pki/issue/my-role common_name="api.internal"
   ```

---

## 5. Threat Model Analysis (Red Team View)

| Attack Vector | Mitigation Status | Notes |
|---------------|-------------------|-------|
| **Packet Sniffing (Wireshark)** | ✅ **BLOCKED** | Payload is encrypted; attacker sees random bytes.  |
| **Man-in-the-Middle (Active Interception)** | ⚠️ **PARTIAL** | Self-signed certs train users to click "Accept Risk".  This is dangerous. Production MUST use trusted CAs to prevent MitM spoofing. |
| **SSL Stripping (sslstrip)** | ⚠️ **VULNERABLE** | Without HSTS header, attacker can downgrade to HTTP. |
| **Certificate Pinning Bypass** | ⚠️ **NOT IMPLEMENTED** | Mobile apps should pin certificates to prevent proxy attacks. |
| **Weak Cipher Suites** | ✅ **MITIGATED** | TLS 1.3 deprecates weak ciphers (RC4, 3DES, MD5). |

### Recommendations: 

1. **Enable HSTS** (HTTP Strict Transport Security)
   ```python
   self.send_header('Strict-Transport-Security', 'max-age=31536000; includeSubDomains')
   ```

2. **Implement Certificate Pinning** (for mobile apps)
3. **Use CAA DNS Records** (specify allowed CAs)
4. **Monitor Certificate Transparency Logs**

---

## 6. Testing Checklist

- [x] Certificate generated with OpenSSL
- [x] Python server configured with SSL context
- [x] Browser shows warning but allows connection
- [x] Certificate details inspected (RSA 2048, self-signed)
- [x] Wireshark confirms encryption (no plaintext visible)
- [x] Server responds with HTML over HTTPS
- [x] TLS 1.3 protocol confirmed in handshake

---

## 7. Learning Outcomes

**What I Learned:**
- 🔐 How TLS handshake works (ClientHello → ServerHello → Certificate → EncryptedData)
- 🆔 Difference between encryption and identity (self-signed encrypts but doesn't authenticate)
- 🏢 Why enterprises use certificate authorities (chain of trust)
- 🛡️ How to implement HTTPS in Python from scratch
- 🔍 How to verify encryption with packet analysis tools

**Enterprise Skills Gained:**
- Certificate generation and management
- Understanding of PKI (Public Key Infrastructure)
- Threat modeling for encrypted communications
- Production vs development security tradeoffs

---

## 8. Next Steps (Phase 2)

- [ ] Implement automated certificate renewal (Let's Encrypt + Certbot)
- [ ] Configure reverse proxy (Nginx) for TLS termination
- [ ] Implement mutual TLS (mTLS) for service-to-service communication
- [ ] Set up certificate monitoring and expiration alerts
- [ ] Harden TLS configuration (disable TLS 1.0/1.1, configure cipher suites)

---

## 9. References

- [RFC 8446 - TLS 1.3 Specification](https://datatracker.ietf.org/doc/html/rfc8446)
- [OWASP:  Transport Layer Protection Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Protection_Cheat_Sheet.html)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

---

**Status:** ✅ Complete  
**Phase 1 Progress:** 7/7 Days Complete 🎉  
**Security Level:** 🔒🔒🔒🔒⚪ (4/5 - Development Ready, Needs Trusted CA for Production)
