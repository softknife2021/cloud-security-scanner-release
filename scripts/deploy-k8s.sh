#!/bin/bash
#
# Deploy ReleasePilot to Kubernetes
# Run from your local machine after configuring values-secrets.yaml
#
# Prerequisites:
#   1. kubectl configured with target cluster
#   2. Docker images pushed to Docker Hub
#   3. values-secrets.yaml created with real passwords
#
# Usage:
#   ./scripts/deploy-k8s.sh                    # Fresh install
#   ./scripts/deploy-k8s.sh upgrade            # Upgrade existing
#   ./scripts/deploy-k8s.sh reset              # Full reset (deletes data!)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHART_DIR="${PROJECT_ROOT}/helm/pilotrelease"
SECRETS_FILE="${CHART_DIR}/values-secrets.yaml"
RELEASE_NAME="pilotrelease"
NAMESPACE="pilotrelease"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ── Preflight checks ──────────────────────────────────────────────
check_prerequisites() {
    log_info "Running preflight checks..."

    if ! command -v kubectl &>/dev/null; then
        log_error "kubectl not found. Install: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi

    if ! command -v helm &>/dev/null; then
        log_error "helm not found. Install: https://helm.sh/docs/intro/install/"
        exit 1
    fi

    if ! kubectl cluster-info &>/dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Check your kubeconfig."
        exit 1
    fi

    if [ ! -f "$SECRETS_FILE" ]; then
        log_error "Secrets file not found: $SECRETS_FILE"
        log_error "Copy the example and fill in real values:"
        log_error "  cp ${CHART_DIR}/values-secrets.example.yaml ${SECRETS_FILE}"
        exit 1
    fi

    # Validate secrets are not empty
    if grep -q '""' "$SECRETS_FILE"; then
        log_warn "Some values in values-secrets.yaml are empty. Make sure all secrets are set."
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] || exit 1
    fi

    log_info "Cluster: $(kubectl config current-context)"
    log_info "Preflight checks passed"
}

# ── Generate secrets helper ───────────────────────────────────────
generate_secrets() {
    log_info "Generating random secrets..."
    cat > "$SECRETS_FILE" << EOF
# Auto-generated secrets — $(date +%Y-%m-%d)
# Keep this file safe. Do NOT commit to git.

postgres:
  password: "$(openssl rand -base64 24 | tr -d '/+=' | cut -c1-24)"

backend:
  jwtSecret: "$(openssl rand -base64 64 | tr -d '/+=' | cut -c1-64)"

app:
  adminUsername: "admin"
  adminPassword: "$(openssl rand -base64 16 | tr -d '/+=' | cut -c1-16)"
  encryptionKey: "$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-32)"

minio:
  rootUser: "minioadmin"
  rootPassword: "$(openssl rand -base64 16 | tr -d '/+=' | cut -c1-16)"

global:
  imagePullPolicy: Always
  imageTag: latest
EOF
    log_info "Secrets written to: $SECRETS_FILE"
    log_warn "Admin password: $(grep adminPassword "$SECRETS_FILE" | head -1 | awk -F'"' '{print $2}')"
    log_warn "Save these credentials somewhere safe!"
}

# ── Install ───────────────────────────────────────────────────────
install() {
    log_info "Installing ${RELEASE_NAME} to namespace ${NAMESPACE}..."

    kubectl create namespace "$NAMESPACE" 2>/dev/null || true

    helm install "$RELEASE_NAME" "$CHART_DIR" \
        -n "$NAMESPACE" \
        -f "$SECRETS_FILE" \
        --wait --timeout 5m

    log_info "Deployment complete!"
    show_status
}

# ── Upgrade ───────────────────────────────────────────────────────
upgrade() {
    log_info "Upgrading ${RELEASE_NAME}..."

    helm upgrade "$RELEASE_NAME" "$CHART_DIR" \
        -n "$NAMESPACE" \
        -f "$SECRETS_FILE" \
        --wait --timeout 5m

    log_info "Upgrade complete!"
    show_status
}

# ── Reset (destructive) ──────────────────────────────────────────
reset() {
    log_warn "This will DELETE all data (database, storage) and reinstall."
    read -p "Are you sure? (type 'yes' to confirm) " -r
    [[ $REPLY == "yes" ]] || { log_info "Cancelled."; exit 0; }

    log_info "Uninstalling..."
    helm uninstall "$RELEASE_NAME" -n "$NAMESPACE" 2>/dev/null || true

    log_info "Deleting PVCs..."
    kubectl delete pvc --all -n "$NAMESPACE" 2>/dev/null || true

    sleep 5
    install
}

# ── Status ────────────────────────────────────────────────────────
show_status() {
    echo ""
    log_info "=== Pod Status ==="
    kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null

    echo ""
    log_info "=== Services ==="
    kubectl get svc -n "$NAMESPACE" --no-headers 2>/dev/null

    echo ""
    log_info "=== Access ==="
    echo "  Port-forward (quick access):"
    echo "    kubectl port-forward svc/${RELEASE_NAME}-ui 3000:80 -n ${NAMESPACE} &"
    echo "    kubectl port-forward svc/${RELEASE_NAME}-backend 8080:8080 -n ${NAMESPACE} &"
    echo ""
    echo "  Then open: http://localhost:3000"
    echo "  Admin:     $(grep adminUsername "$SECRETS_FILE" 2>/dev/null | head -1 | awk -F'"' '{print $2}') / $(grep adminPassword "$SECRETS_FILE" 2>/dev/null | head -1 | awk -F'"' '{print $2}')"
}

# ── Main ──────────────────────────────────────────────────────────
ACTION="${1:-install}"

case "$ACTION" in
    install)
        check_prerequisites
        install
        ;;
    upgrade)
        check_prerequisites
        upgrade
        ;;
    reset)
        check_prerequisites
        reset
        ;;
    generate-secrets)
        generate_secrets
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {install|upgrade|reset|generate-secrets|status}"
        exit 1
        ;;
esac
