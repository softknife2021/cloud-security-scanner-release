# Cloud Security Scanner

A cloud-native security scanning platform with a web UI for managing vulnerability scans, API security testing, UI testing, and performance testing.

## Prerequisites

- Docker and Docker Compose installed
- Minimum 4GB RAM available for Docker

## Quick Start

```bash
# 1. Clone this repo
git clone https://github.com/softknife2021/cloud-security-scanner-release.git
cd cloud-security-scanner-release

# 2. Start everything (handles JWT tokens, health checks, all services)
./scripts/start-all.sh
```

Open http://localhost:3000 and login with `admin` / `admin123`

### Start Options

```bash
./scripts/start-all.sh              # Everything (all profiles)
./scripts/start-all.sh core         # Just database + backend + UI
./scripts/start-all.sh scanners     # Core + all scanner agents
./scripts/start-all.sh ui-test      # Core + Selenium + UI test agent
```

## Default Credentials

| User | Password | Roles |
|------|----------|-------|
| admin | admin123 | ADMIN, ANALYST, VIEWER |
| analyst | analyst123 | ANALYST, VIEWER |
| viewer | viewer123 | VIEWER |

## Services

| Service | URL | Description |
|---------|-----|-------------|
| UI | http://localhost:3000 | Web dashboard |
| Backend API | http://localhost:8080 | REST API |
| Database | localhost:5433 | PostgreSQL |

## Optional Profiles

Enable additional services with `--profile`:

```bash
# UI Testing (Selenium + WebDriver agent)
docker-compose --env-file local.env --profile ui-test up -d

# Security Scanner Agent (core: nmap, nikto, sqlmap, nuclei, trivy, kubectl)
docker-compose --env-file local.env --profile scanner up -d

# Scanner with OWASP ZAP (web app security scanning)
docker-compose --env-file local.env --profile scanner-zap up -d

# Scanner with Artillery (performance/load testing)
docker-compose --env-file local.env --profile scanner-artillery up -d

# S3 Storage (MinIO)
docker-compose --env-file local.env --profile storage up -d

# Vulnerable test target (DVWA)
docker-compose --env-file local.env --profile target up -d

# All profiles
docker-compose --env-file local.env --profile scanner --profile scanner-zap --profile scanner-artillery --profile ui-test --profile storage --profile target up -d
```

### Scanner Agent Setup

`start-all.sh` handles JWT token generation and scanner startup automatically. For manual setup:

```bash
# Get a token and start scanner
TOKEN=$(curl -s http://localhost:8080/api/auth/login -X POST \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

SCANNER_JWT_TOKEN=$TOKEN docker-compose --env-file local.env --profile scanner up -d
```

### UI Testing

When running with `--profile ui-test`, a Selenium Chrome browser and WebDriver agent are started. Access the Selenium VNC viewer at http://localhost:7900 (password: `secret`) to watch tests run.

## Configuration

Edit `local.env` to customize ports, passwords, and settings. See the comments in the file for details.

## Stopping

```bash
# Stop all services
docker-compose --env-file local.env down

# Stop and remove data
docker-compose --env-file local.env down -v
```

## Architecture

```
Browser → UI (React/Nginx:3000) → Backend API (Spring Boot:8080) → PostgreSQL
                                         ↑
                              Scanner Agent (Python) - polls for jobs
                              UI Test Agent (Java/Selenium) - polls for UI test jobs
```

## Images

All images are hosted on Docker Hub under `softknife/`:

- `softknife/cloud-security-agent` - Backend API
- `softknife/cloud-security-ui` - Web UI
- `softknife/cloud-security-scanner` - Core scanner agent (235 MB)
- `softknife/cloud-security-scanner-zap` - Scanner + OWASP ZAP (654 MB)
- `softknife/cloud-security-scanner-artillery` - Scanner + Artillery (610 MB)
- `softknife/cloud-security-ui-test-agent` - UI test agent
