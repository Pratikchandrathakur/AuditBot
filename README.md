# 🛡️ AuditBot (Currently in Active Development)

**Project Status:** 🚧 Alpha Build (Expected Release: Jan 30, 2026)

## 🎯 Problem Statement
Manual security audits of AWS environments are slow, error-prone, and unscalable. Small teams often leave S3 buckets public or IAM roles over-privileged because they lack the budget for enterprise tools like Wiz or Prisma Cloud.

## 💡 The Solution: AuditBot
AuditBot is a lightweight, automated Python-based security auditor designed to run in CI/CD pipelines. It utilizes `boto3` to perform non-invasive scans of AWS accounts against CIS Benchmarks.

## 📐 Architecture (Planned)
[CLI Client] -> [Python Logic Layer] -> [Boto3] -> [AWS API]
                                            |
                                      [Report Generator] -> [JSON/HTML Output]

## ✅ Roadmap
- [ ] **Phase 1:** Core Scripting (S3 & IAM Modules) - *In Progress*
- [ ] **Phase 2:** CLI Wrapper & Dockerization
- [ ] **Phase 3:** Flask API Implementation

## 🛠️ Tech Stack
- **Language:** Python 3.9
- **SDK:** AWS Boto3
- **Container:** Docker (Distroless)
- **Testing:** Pytest
