#!/bin/bash
# =============================================================================
# Cloud Security Scanner - Start All Services
# =============================================================================
#
# One-command startup for the entire platform. Handles cleanup, JWT tokens,
# health checks, and all Docker profiles automatically.
#
# Usage:
#   ./scripts/start-all.sh              # Start everything (all profiles)
#   ./scripts/start-all.sh core         # Just postgres + backend + UI
#   ./scripts/start-all.sh scanners     # Core + all scanner agents
#   ./scripts/start-all.sh ui-test      # Core + selenium + ui-test-agent
#   ./scripts/start-all.sh --fresh      # Wipe DB and re-init from 01-init.sql
#   ./scripts/start-all.sh --fresh all  # Fresh DB + all profiles
#   ./scripts/start-all.sh --no-pull    # Skip pulling images (use local cache)
#
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
COMPOSE_FILE="docker-compose.yml"
ENV_FILE="local.env"
API_PORT="${APP_PORT:-8080}"
API_URL="http://localhost:${API_PORT}"
FRESH_DB=false
SKIP_PULL=false

# Parse arguments
MODE="all"
for arg in "$@"; do
    case "$arg" in
        --fresh) FRESH_DB=true ;;
        --no-pull) SKIP_PULL=true ;;
        core|scanners|ui-test|all) MODE="$arg" ;;
        *) echo -e "${RED}Unknown argument: $arg${NC}"; exit 1 ;;
    esac
done

# All known container names (for cleanup)
CONTAINERS=(
    cloud-security-agent-postgres
    cloud-security-agent-app
    cloud-security-agent-ui
    cloud-security-scanner-agent
    cloud-security-scanner-zap
    cloud-security-scanner-artillery
    cloud-security-minio
    cloud-security-minio-init
    cloud-security-selenium
    cloud-security-test-target
    cloud-security-ui-test-agent
)

# Profile sets
ALL_PROFILES="--profile scanner --profile scanner-zap --profile scanner-artillery --profile storage --profile ui-test --profile target"
SCANNER_PROFILES="--profile scanner --profile scanner-zap --profile scanner-artillery"
UI_TEST_PROFILES="--profile ui-test"

# =============================================================================
echo -e "${CYAN}${BOLD}"
echo "=============================================="
echo "  Cloud Security Scanner - Full Stack Setup"
echo "=============================================="
echo -e "${NC}"
echo -e "  Mode:     ${BOLD}${MODE}${NC}"
echo -e "  Compose:  ${COMPOSE_FILE}"
[ "$FRESH_DB" = true ] && echo -e "  Fresh DB: ${YELLOW}yes (volumes will be wiped)${NC}"
[ "$SKIP_PULL" = true ] && echo -e "  Pull:     ${YELLOW}skipped (using local images)${NC}"
echo ""

# =============================================================================
# Step 1: Pre-flight checks
# =============================================================================
echo -e "${YELLOW}[1/9]${NC} Pre-flight checks..."

# Check Docker
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}ERROR: Docker is not running.${NC}"
    echo "  Start Docker Desktop and try again."
    exit 1
fi
echo -e "  ${GREEN}Docker is running${NC}"

# Check docker-compose
if ! docker-compose version > /dev/null 2>&1; then
    echo -e "${RED}ERROR: docker-compose not found.${NC}"
    echo "  Install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi
echo -e "  ${GREEN}docker-compose available${NC}"

# Check project root
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}ERROR: $COMPOSE_FILE not found.${NC}"
    echo "  Run this script from the project root directory:"
    echo "    cd /path/to/cloud-security-scanner-release && ./scripts/start-all.sh"
    exit 1
fi
echo -e "  ${GREEN}Project root verified${NC}"

# =============================================================================
# Step 2: Environment file
# =============================================================================
echo -e "${YELLOW}[2/9]${NC} Checking environment..."

if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}ERROR: ${ENV_FILE} not found.${NC}"
    echo "  This file should be included in the release repository."
    exit 1
fi
echo -e "  ${GREEN}${ENV_FILE} exists${NC}"

# =============================================================================
# Step 3: Docker volumes
# =============================================================================
echo -e "${YELLOW}[3/9]${NC} Checking Docker volumes..."
echo -e "  ${GREEN}Volumes managed by compose${NC}"

# =============================================================================
# Step 4: Cleanup
# =============================================================================
echo -e "${YELLOW}[4/9]${NC} Cleaning up old containers..."

# Try compose down first (catches compose-managed containers)
if [ "$FRESH_DB" = true ]; then
    echo -e "  ${YELLOW}--fresh: Removing database volume for clean init${NC}"
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" \
        $ALL_PROFILES down --remove-orphans -v 2>/dev/null || true
else
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" \
        $ALL_PROFILES down --remove-orphans 2>/dev/null || true
fi

# Force-remove any leftover containers by name
for container in "${CONTAINERS[@]}"; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        docker rm -f "$container" > /dev/null 2>&1 || true
    fi
done
echo -e "  ${GREEN}Clean slate${NC}"

# =============================================================================
# Step 5: Resolve profiles
# =============================================================================
PROFILES=""
case "$MODE" in
    all)      PROFILES="$ALL_PROFILES" ;;
    core)     PROFILES="" ;;
    scanners) PROFILES="$SCANNER_PROFILES" ;;
    ui-test)  PROFILES="$UI_TEST_PROFILES" ;;
    *)        echo -e "${RED}Unknown mode: $MODE${NC}"; echo "  Use: all, core, scanners, ui-test"; exit 1 ;;
esac

# =============================================================================
# Step 5b: Pull images
# =============================================================================
if [ "$SKIP_PULL" = true ]; then
    echo -e "${YELLOW}[5/9]${NC} Skipping image pull (--no-pull)"
else
    echo -e "${YELLOW}[5/9]${NC} Checking and pulling images..."

    # Only pulls images NOT already cached locally to avoid Docker Hub rate limits
    # (free accounts: 100 pulls per 6 hours). Uses --platform linux/amd64 for
    # amd64-only images so they work on Apple Silicon via Rosetta.

    # Build image lists based on mode
    AMD64_IMAGES="softknife/cloud-security-agent:latest"
    MULTIARCH_IMAGES="softknife/cloud-security-ui:latest postgres:14-alpine"

    case "$MODE" in
        all|scanners)
            AMD64_IMAGES="$AMD64_IMAGES softknife/cloud-security-scanner:latest"
            AMD64_IMAGES="$AMD64_IMAGES softknife/cloud-security-scanner-zap:latest"
            AMD64_IMAGES="$AMD64_IMAGES softknife/cloud-security-scanner-artillery:latest"
            ;;
    esac
    case "$MODE" in
        all|ui-test)
            AMD64_IMAGES="$AMD64_IMAGES softknife/cloud-security-ui-test-agent:latest"
            SELENIUM_IMG=$(grep "^SELENIUM_IMAGE=" "$ENV_FILE" 2>/dev/null | cut -d= -f2)
            MULTIARCH_IMAGES="$MULTIARCH_IMAGES ${SELENIUM_IMG:-seleniarm/standalone-chromium:latest}"
            ;;
    esac
    case "$MODE" in
        all)
            AMD64_IMAGES="$AMD64_IMAGES vulnerables/web-dvwa:latest"
            MULTIARCH_IMAGES="$MULTIARCH_IMAGES minio/minio:latest minio/mc:latest"
            ;;
    esac

    PULL_COUNT=0
    SKIP_COUNT=0
    FAIL_COUNT=0

    # Helper: pull if not cached
    pull_if_missing() {
        local img="$1"
        local platform_flag="$2"
        if docker image inspect "$img" > /dev/null 2>&1; then
            echo -e "  ${GREEN}Cached:${NC}  ${img}"
            SKIP_COUNT=$((SKIP_COUNT + 1))
        else
            echo -e "  ${CYAN}Pulling:${NC} ${img}..."
            if docker pull $platform_flag "$img" 2>&1 | tail -1; then
                PULL_COUNT=$((PULL_COUNT + 1))
            else
                echo -e "  ${RED}Failed:${NC}  ${img} (Docker Hub rate limit?)"
                FAIL_COUNT=$((FAIL_COUNT + 1))
            fi
        fi
    }

    for img in $AMD64_IMAGES; do
        pull_if_missing "$img" "--platform linux/amd64"
    done
    for img in $MULTIARCH_IMAGES; do
        pull_if_missing "$img" ""
    done

    echo ""
    echo -e "  ${GREEN}Done:${NC} ${PULL_COUNT} pulled, ${SKIP_COUNT} cached, ${FAIL_COUNT} failed"
    if [ $FAIL_COUNT -gt 0 ]; then
        echo -e "  ${YELLOW}Some images failed to pull. If rate-limited, try:${NC}"
        echo -e "  ${YELLOW}  1. Wait 1-2 hours and run again${NC}"
        echo -e "  ${YELLOW}  2. Login to Docker Hub: docker login${NC}"
        echo -e "  ${YELLOW}  3. Re-run with --no-pull if images are already cached${NC}"
    fi
fi

# =============================================================================
# Step 6: Start core services
# =============================================================================
echo -e "${YELLOW}[6/9]${NC} Starting core services (postgres, backend, UI)..."

docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d \
    postgres security-agent security-agent-ui 2>&1 | grep -v "^$" || true

# =============================================================================
# Step 7: Wait for backend
# =============================================================================
echo -e "${YELLOW}[7/9]${NC} Waiting for backend to be healthy..."

MAX_WAIT=90
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/actuator/health" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "  ${GREEN}Backend is healthy${NC} (${ELAPSED}s)"
        break
    fi
    sleep 3
    ELAPSED=$((ELAPSED + 3))
    # Print progress every 15 seconds
    if [ $((ELAPSED % 15)) -eq 0 ]; then
        echo -e "  Waiting... (${ELAPSED}s / ${MAX_WAIT}s)"
    fi
done

if [ "$HTTP_CODE" != "200" ]; then
    echo -e "${RED}ERROR: Backend failed to start after ${MAX_WAIT}s${NC}"
    echo "  Check logs: docker logs cloud-security-agent-app"
    exit 1
fi

# =============================================================================
# Step 8: Get JWT token and start profiles
# =============================================================================
if [ -n "$PROFILES" ]; then
    echo -e "${YELLOW}[8/9]${NC} Getting JWT token for scanner agents..."

    RESPONSE=$(curl -s "$API_URL/api/auth/login" \
        -X POST \
        -H "Content-Type: application/json" \
        -d '{"username": "admin", "password": "admin123"}' 2>/dev/null)

    TOKEN=$(echo "$RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

    if [ -z "$TOKEN" ]; then
        echo -e "${RED}WARNING: Could not get JWT token. Scanners may not authenticate.${NC}"
        echo "  Response: $RESPONSE"
        echo "  Continuing anyway..."
    else
        echo -e "  ${GREEN}Token obtained (${#TOKEN} chars)${NC}"

        # Write token to local.env so docker-compose picks it up
        if grep -q "^SCANNER_JWT_TOKEN=" "$ENV_FILE"; then
            sed -i.bak "s|^SCANNER_JWT_TOKEN=.*|SCANNER_JWT_TOKEN=${TOKEN}|" "$ENV_FILE"
            rm -f "${ENV_FILE}.bak"
        else
            echo "SCANNER_JWT_TOKEN=${TOKEN}" >> "$ENV_FILE"
        fi
        echo -e "  ${GREEN}Token saved to ${ENV_FILE}${NC}"
    fi

    echo -e "${YELLOW}[9/9]${NC} Starting profile services (${MODE})..."

    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" \
        $PROFILES up -d 2>&1 | grep -v "^$" || true
else
    echo -e "${YELLOW}[8/9]${NC} Skipping scanner token (core mode)"
    echo -e "${YELLOW}[9/9]${NC} No profiles to start (core mode)"
fi

# =============================================================================
# Health Summary
# =============================================================================
echo ""
echo -e "${CYAN}Waiting for services to stabilize...${NC}"
sleep 8

echo ""
echo -e "${CYAN}${BOLD}=============================================="
echo "  Service Status"
echo "==============================================${NC}"
echo ""

# Print container status table
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" \
    --filter "name=cloud-security" 2>/dev/null | head -20

echo ""
echo -e "${CYAN}${BOLD}=============================================="
echo "  Access URLs"
echo "==============================================${NC}"
echo ""
echo -e "  ${BOLD}UI:${NC}              http://localhost:3000"
echo -e "  ${BOLD}Backend API:${NC}     http://localhost:8080"
echo -e "  ${BOLD}API Health:${NC}      http://localhost:8080/actuator/health"

if echo "$PROFILES" | grep -q "storage"; then
    echo -e "  ${BOLD}MinIO Console:${NC}   http://localhost:9001"
fi
if echo "$PROFILES" | grep -q "ui-test"; then
    echo -e "  ${BOLD}Selenium VNC:${NC}    http://localhost:7900  (password: secret)"
fi
if echo "$PROFILES" | grep -q "target"; then
    echo -e "  ${BOLD}DVWA Target:${NC}     http://localhost:8888"
fi

echo ""
echo -e "${CYAN}${BOLD}=============================================="
echo "  Default Credentials"
echo "==============================================${NC}"
echo ""
echo -e "  ${BOLD}Admin:${NC}    admin / admin123"
echo -e "  ${BOLD}Analyst:${NC}  analyst / analyst123"
echo -e "  ${BOLD}Viewer:${NC}   viewer / viewer123"

echo ""
echo -e "${CYAN}${BOLD}=============================================="
echo "  Useful Commands"
echo "==============================================${NC}"
echo ""
echo "  View logs:      docker logs -f cloud-security-agent-app"
echo "  Scanner logs:   docker logs -f cloud-security-scanner-agent"
echo "  Stop all:       docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE $ALL_PROFILES down"
echo "  Restart:        ./scripts/start-all.sh ${MODE}"
echo ""
echo -e "${GREEN}${BOLD}Setup complete.${NC}"
echo ""
