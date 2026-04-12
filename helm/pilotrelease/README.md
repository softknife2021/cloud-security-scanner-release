# Cloud Security Scanner - Helm Chart

Deploy the full Cloud Security Scanner stack to Kubernetes.

## Prerequisites

- Kubernetes cluster (Minikube, Docker Desktop, etc.)
- Helm 3.x
- `kubectl` configured

## Quick Start (Minikube)

```bash
# Start Minikube
minikube start

# Install the chart
helm install scanner ./helm/cloud-security-scanner/

# Wait for pods to be ready (~90s for backend)
kubectl get pods -l app.kubernetes.io/instance=scanner -w

# Access services
minikube service scanner-ui --url        # UI
minikube service scanner-backend --url   # API
minikube service scanner-minio --url     # MinIO Console
```

## Services

| Component | Port | NodePort | Description |
|-----------|------|----------|-------------|
| UI | 80 | 30000 | React frontend |
| Backend | 8080 | 30080 | Spring Boot API |
| PostgreSQL | 5432 | - | Database (internal only) |
| Scanner Agent | - | - | Python scanner (no exposed port) |
| MinIO API | 9000 | 30900 | S3-compatible storage |
| MinIO Console | 9001 | 30901 | MinIO web UI |

## Default Credentials

| Service | Username | Password |
|---------|----------|----------|
| App | admin | admin123 |
| MinIO | minioadmin | minioadmin |
| Database | secadmin | secpass123 |

## Customizing Values

```bash
# Override on install
helm install scanner ./helm/cloud-security-scanner/ \
  --set app.adminPassword=mySecurePass \
  --set backend.replicas=2 \
  --set minio.storage=20Gi

# Or create a custom values file
helm install scanner ./helm/cloud-security-scanner/ -f my-values.yaml
```

### Key Values

| Value | Default | Description |
|-------|---------|-------------|
| `global.imageTag` | latest | Image tag for all app images |
| `backend.replicas` | 1 | Backend pod replicas |
| `backend.jwtSecret` | (default) | JWT signing key |
| `postgres.storage` | 5Gi | Database PVC size |
| `minio.enabled` | true | Deploy MinIO |
| `minio.storage` | 10Gi | MinIO PVC size |
| `scanner.replicas` | 1 | Scanner agent replicas |
| `scanner.pollInterval` | 30 | Job poll interval (seconds) |
| `serviceType` | NodePort | Service type (NodePort/ClusterIP/LoadBalancer) |
| `ingress.enabled` | false | Enable Ingress |
| `ingress.host` | security-scanner.local | Ingress hostname |

## Database Provisioning

The chart uses a custom PostgreSQL image (`softknife/cloud-security-postgres`) with all schema and seed data baked in. On first install, PostgreSQL automatically executes all init scripts, creating:

- Full database schema
- Default users (admin, analyst, viewer)
- Scan templates (nmap NSE scripts, nuclei, etc.)
- Environments and sample data

**Important caveat:** Kubernetes does not automatically delete PersistentVolumeClaims on `helm uninstall`. This means:

- Re-installing the chart will reuse the existing database (init scripts won't re-run)
- To fully reset the database, you must delete the PVC manually:

```bash
helm uninstall scanner
kubectl delete pvc scanner-postgres-data
helm install scanner ./helm/cloud-security-scanner/
```

This applies to MinIO storage as well:

```bash
# Full reset (all data)
helm uninstall scanner
kubectl delete pvc scanner-postgres-data scanner-minio-data
helm install scanner ./helm/cloud-security-scanner/
```

## Upgrade

```bash
helm upgrade scanner ./helm/cloud-security-scanner/
```

## Uninstall

```bash
# Remove deployments (keeps PVCs/data)
helm uninstall scanner

# Remove everything including data
helm uninstall scanner
kubectl delete pvc -l app.kubernetes.io/instance=scanner
```

## Ingress (Optional)

Enable Ingress for a single hostname:

```bash
helm install scanner ./helm/cloud-security-scanner/ \
  --set ingress.enabled=true \
  --set ingress.host=scanner.mycompany.com \
  --set serviceType=ClusterIP
```

Routes:
- `/api/*` and `/actuator/*` -> Backend
- `/*` -> UI

## Useful Commands

```bash
# Pod status
kubectl get pods -l app.kubernetes.io/instance=scanner

# Backend logs
kubectl logs -l app.kubernetes.io/instance=scanner,app.kubernetes.io/component=backend -f

# Scanner agent logs
kubectl logs -l app.kubernetes.io/instance=scanner,app.kubernetes.io/component=scanner -f

# Database shell
kubectl exec -it $(kubectl get pod -l app.kubernetes.io/component=postgres -o name) -- psql -U secadmin -d security_agent

# Restart a component
kubectl rollout restart deployment scanner-backend
```
