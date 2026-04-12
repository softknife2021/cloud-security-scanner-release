# ReleasePilot — Deployment Guide

## Quick Start (Docker Compose)

```bash
git clone https://github.com/softknife2021/cloud-security-scanner-release.git
cd cloud-security-scanner-release

# Start core services
docker-compose up -d

# Wait ~60 seconds, then access:
#   UI:  http://localhost:3000
#   API: http://localhost:8080
#   Credentials: admin / admin123
```

### Profiles (optional agents)

```bash
# UI testing (Selenium + WebDriver)
docker-compose --profile ui-test up -d

# Performance testing (Artillery)
docker-compose --profile performance up -d

# ZAP DAST scanning
docker-compose --profile scanner-zap up -d

# S3 storage (MinIO)
docker-compose --profile storage up -d

# Everything
docker-compose --profile ui-test --profile performance --profile scanner-zap --profile storage up -d
```

### Stop

```bash
docker-compose down          # stop
docker-compose down -v       # stop + reset data
```

---

## Kubernetes (Production)

### Prerequisites

- Kubernetes cluster (any: Hetzner, AWS EKS, GKE, AKS, or minikube for local)
- Helm 3.x
- `kubectl` configured and pointing to your cluster
- Images available on Docker Hub (already published)

### First-Time Setup

```bash
cd cloud-security-scanner-release

# 1. Generate production secrets (random passwords, JWT keys)
./scripts/deploy-k8s.sh generate-secrets

# 2. Review and save the admin password printed to screen
#    Secrets are stored in: helm/pilotrelease/values-secrets.yaml
#    This file is gitignored — keep it safe

# 3. Deploy
./scripts/deploy-k8s.sh install
```

That's it. The script creates the namespace, deploys all components, initializes the database, creates the MinIO bucket, and starts all agents. No manual configuration needed.

### Access the Platform

**With port-forward (minikube or any cluster):**
```bash
kubectl port-forward svc/pilotrelease-ui 3000:80 -n pilotrelease &
kubectl port-forward svc/pilotrelease-backend 8080:8080 -n pilotrelease &

# Open http://localhost:3000
```

**With Ingress (production cluster):**
```bash
# Edit values-secrets.yaml and add:
#   ingress:
#     enabled: true
#     host: pilotrelease.yourdomain.com
#   serviceType: ClusterIP

./scripts/deploy-k8s.sh upgrade
```

### Day-to-Day Operations

```bash
# Check status
./scripts/deploy-k8s.sh status

# Upgrade after new image release
./scripts/deploy-k8s.sh upgrade

# View logs
kubectl logs -f -l app.kubernetes.io/component=backend -n pilotrelease
kubectl logs -f -l app.kubernetes.io/component=scanner -n pilotrelease

# Restart a component
kubectl rollout restart deployment/pilotrelease-backend -n pilotrelease

# Scale scanner agents
kubectl scale deployment/pilotrelease-scanner --replicas=3 -n pilotrelease

# Full reset (deletes ALL data)
./scripts/deploy-k8s.sh reset
```

### What Gets Deployed

| Component | Pod | Purpose |
|-----------|-----|---------|
| PostgreSQL | pilotrelease-postgres | Database with schema + seed data |
| Backend API | pilotrelease-backend | Spring Boot REST API |
| Frontend UI | pilotrelease-ui | React + Nginx |
| Selenium | pilotrelease-selenium | Chrome for element picker |
| MinIO | pilotrelease-minio | S3-compatible storage for reports |
| Scanner Agent | pilotrelease-scanner | Nmap, Nuclei, Nikto, SQLMap, Trivy |
| ZAP Agent | pilotrelease-zap | OWASP ZAP DAST scanning |
| Artillery Agent | pilotrelease-artillery | Performance/load testing |
| UI Test Agent | pilotrelease-ui-test-agent | WebDriver + crawler (includes Selenium sidecar) |

All agents self-register with the backend on startup. No manual agent configuration required.

---

## Images (Docker Hub)

| Image | Purpose |
|-------|---------|
| `softknife/pilotrelease-backend` | Backend API (Spring Boot) |
| `softknife/pilotrelease-ui` | Frontend (React + Nginx) |
| `softknife/pilotrelease-scanner` | Security scanner (Nmap, Nuclei, SQLMap, Nikto, Trivy) |
| `softknife/pilotrelease-scanner-zap` | ZAP DAST scanner |
| `softknife/pilotrelease-performance` | Performance testing (Artillery) |
| `softknife/pilotrelease-ui-test` | UI test agent (Selenium WebDriver + Crawler) |

---

## Default Credentials

| User | Password | Roles |
|------|----------|-------|
| admin | admin123 | ADMIN, ANALYST, VIEWER |

> **Production:** Run `./scripts/deploy-k8s.sh generate-secrets` to create random passwords. The default credentials above are only used with Docker Compose.

---

## Secrets Management

Secrets are managed via a local `values-secrets.yaml` file that is **never committed to git**.

```bash
# Generate random secrets
./scripts/deploy-k8s.sh generate-secrets

# File created: helm/pilotrelease/values-secrets.yaml
# Contains: DB password, JWT secret, admin password, encryption key, MinIO credentials
```

For the example template, see `helm/pilotrelease/values-secrets.example.yaml`.

---

## Architecture

```
                    ┌──────────┐
                    │    UI    │ :3000
                    └────┬─────┘
                         │
                    ┌────▼─────┐
                    │ Backend  │ :8080
                    └────┬─────┘
                         │
              ┌──────────┼──────────┐
              │          │          │
        ┌─────▼──┐  ┌───▼────┐  ┌──▼──────┐
        │Postgres│  │ MinIO  │  │Selenium │
        └────────┘  └────────┘  └─────────┘
              │
    ┌─────────┼─────────┬──────────┐
    │         │         │          │
┌───▼───┐ ┌──▼───┐ ┌───▼──┐ ┌────▼───┐
│Scanner│ │ ZAP  │ │Artil.│ │UI Test │
│Agent  │ │Agent │ │Agent │ │ Agent  │
└───────┘ └──────┘ └──────┘ └────────┘
```
