# ReleasePilot — Helm Chart

Deploy the full ReleasePilot platform to any Kubernetes cluster.

## Prerequisites

- Kubernetes cluster (minikube, Hetzner, AWS EKS, GKE, AKS, etc.)
- Helm 3.x
- `kubectl` configured

## Quick Deploy

```bash
# Generate production secrets (one time)
../scripts/deploy-k8s.sh generate-secrets

# Install
../scripts/deploy-k8s.sh install

# Or manually:
kubectl create namespace pilotrelease
helm install pilotrelease . -n pilotrelease -f values-secrets.yaml
```

## What Gets Deployed

| Component | Service | Ports | Description |
|-----------|---------|-------|-------------|
| Backend API | pilotrelease-backend | 8080 (NodePort 30080) | Spring Boot REST API |
| Frontend UI | pilotrelease-ui | 80 (NodePort 30000) | React + Nginx |
| PostgreSQL | pilotrelease-postgres | 5432 (ClusterIP) | Database |
| Selenium | pilotrelease-selenium | 4444, 7900 (ClusterIP) | Chrome for element picker |
| MinIO | pilotrelease-minio | 9000, 9001 (NodePort 30900/30901) | S3 storage |
| Scanner Agent | pilotrelease-scanner | — | Nmap, Nuclei, Nikto, SQLMap, Trivy |
| ZAP Agent | pilotrelease-zap | — | OWASP ZAP DAST scanning |
| Artillery Agent | pilotrelease-artillery | — | Performance/load testing |
| UI Test Agent | pilotrelease-ui-test-agent | — | WebDriver + Crawler (Selenium sidecar) |
| Backend Alias | security-agent | 8080 (ClusterIP) | Nginx proxy target alias |

## Secrets

**Never use default passwords in production.** Generate real secrets:

```bash
# Auto-generate random passwords
../scripts/deploy-k8s.sh generate-secrets
# Creates: values-secrets.yaml (gitignored)
```

Or copy the example and fill in manually:
```bash
cp values-secrets.example.yaml values-secrets.yaml
# Edit values-secrets.yaml with real passwords
```

### What's in the secrets file

| Secret | Purpose |
|--------|---------|
| `postgres.password` | Database password |
| `backend.jwtSecret` | JWT signing key (min 64 chars) |
| `app.adminPassword` | Initial admin user password |
| `app.encryptionKey` | AES-256 key for credential vault (exactly 32 chars) |
| `minio.rootUser` | MinIO access key |
| `minio.rootPassword` | MinIO secret key |

## Customizing Values

```bash
# Override at install time
helm install pilotrelease . -n pilotrelease \
  -f values-secrets.yaml \
  --set backend.replicas=2 \
  --set minio.storage=20Gi

# Or create a custom values file
helm install pilotrelease . -n pilotrelease \
  -f values-secrets.yaml \
  -f values-custom.yaml
```

### Key Values

| Value | Default | Description |
|-------|---------|-------------|
| `global.imageTag` | latest | Image tag for all custom images |
| `global.imagePullPolicy` | IfNotPresent | Set to `Always` for production |
| `backend.replicas` | 1 | Backend pod replicas |
| `postgres.storage` | 5Gi | Database PVC size |
| `minio.enabled` | true | Deploy MinIO |
| `minio.storage` | 10Gi | MinIO PVC size |
| `scanner.replicas` | 1 | Scanner agent replicas |
| `serviceType` | NodePort | Service type (NodePort/ClusterIP/LoadBalancer) |
| `ingress.enabled` | false | Enable Ingress |
| `ingress.host` | security-scanner.local | Ingress hostname |

## Database

The database is initialized automatically on first install via ConfigMap-mounted SQL scripts:

- `00-init-db.sql` — Extensions (uuid-ossp, pgcrypto)
- `01-schema.sql` — Full schema (tables, indexes, constraints)
- `02-seed-data.sql` — Seed data (admin user, scan templates, presets)

Scripts only run when the PVC is empty (first boot). To re-initialize:

```bash
helm uninstall pilotrelease -n pilotrelease
kubectl delete pvc pilotrelease-postgres-data -n pilotrelease
helm install pilotrelease . -n pilotrelease -f values-secrets.yaml
```

## Ingress (Production)

```bash
helm install pilotrelease . -n pilotrelease \
  -f values-secrets.yaml \
  --set ingress.enabled=true \
  --set ingress.host=pilotrelease.yourdomain.com \
  --set serviceType=ClusterIP
```

Routes:
- `/api/*` and `/actuator/*` → Backend
- `/*` → UI

## Operations

```bash
# Pod status
kubectl get pods -n pilotrelease

# Backend logs
kubectl logs -f -l app.kubernetes.io/component=backend -n pilotrelease

# Scanner agent logs
kubectl logs -f -l app.kubernetes.io/component=scanner -n pilotrelease

# All agent logs
for c in scanner zap artillery; do
  echo "=== $c ===" && kubectl logs -l app.kubernetes.io/component=$c -n pilotrelease --tail=5
done

# Database shell
kubectl exec -it deploy/pilotrelease-postgres -n pilotrelease -- psql -U secadmin -d security_agent

# Upgrade
helm upgrade pilotrelease . -n pilotrelease -f values-secrets.yaml

# Uninstall (keeps data)
helm uninstall pilotrelease -n pilotrelease

# Full reset (deletes data)
helm uninstall pilotrelease -n pilotrelease
kubectl delete pvc --all -n pilotrelease
```
