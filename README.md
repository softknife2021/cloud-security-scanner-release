# PilotRelease Platform — Deployment Guide

## Quick Start (Docker Compose)

```bash
git clone <this-repo-url>
cd pilotrelease-release

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

## Kubernetes (Helm)

```bash
# Start minikube (local) or use existing cluster
minikube start --cpus=2 --memory=4096

# Deploy
kubectl create namespace pilotrelease
helm install pilotrelease ./helm/pilotrelease -n pilotrelease

# Wait for pods to be ready (~2 minutes)
kubectl get pods -n pilotrelease -w

# Access the platform (run in separate terminal, keep it running)
kubectl port-forward svc/pilotrelease-ui 3000:80 -n pilotrelease &
kubectl port-forward svc/pilotrelease-backend 8080:8080 -n pilotrelease &

# Open in browser
#   UI:  http://localhost:3000
#   API: http://localhost:8080
#   Credentials: admin / admin123
```

> **Note:** On minikube (Mac/Windows), port-forward is required because minikube runs inside Docker. On a real K8s cluster with an Ingress controller or LoadBalancer, access is direct via the cluster's external IP or domain.

### Common K8s Commands

```bash
# Logs
kubectl logs -f -l app.kubernetes.io/component=backend -n pilotrelease

# Restart
kubectl rollout restart deployment/pilotrelease-backend -n pilotrelease

# Scale
kubectl scale deployment/pilotrelease-scanner --replicas=3 -n pilotrelease

# Reset (delete data + reinstall)
helm uninstall pilotrelease -n pilotrelease
kubectl delete pvc -l app.kubernetes.io/instance=pilotrelease -n pilotrelease
helm install pilotrelease ./helm/pilotrelease -n pilotrelease
```

---

## Images (Docker Hub)

| Image | Purpose |
|-------|---------|
| `softknife/pilotrelease-backend` | Backend API (Spring Boot) |
| `softknife/pilotrelease-ui` | Frontend (React) |
| `softknife/pilotrelease-scanner` | Security scanner (Nmap, Nuclei, SQLMap, Nikto) |
| `softknife/pilotrelease-scanner-zap` | ZAP DAST scanner |
| `softknife/pilotrelease-performance` | Performance testing (Artillery) |
| `softknife/pilotrelease-ui-test` | UI test agent (WebDriver) |

---

## Default Credentials

| User | Password | Roles |
|------|----------|-------|
| admin | admin123 | ADMIN, ANALYST, VIEWER |
| analyst | analyst123 | ANALYST, VIEWER |
| viewer | viewer123 | VIEWER |

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
│Scanner│ │ ZAP  │ │ Perf │ │UI Test │
└───────┘ └──────┘ └──────┘ └────────┘
```
