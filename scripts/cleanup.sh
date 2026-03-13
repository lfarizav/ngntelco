#!/usr/bin/env bash
# cleanup.sh — Remove all ngntelco containers, networks, and volumes
# Usage: ./scripts/cleanup.sh [--all]

set -euo pipefail

echo "╔══════════════════════════════════════════╗"
echo "║   ngntelco — Cleanup                     ║"
echo "╚══════════════════════════════════════════╝"
echo ""

cd "$(dirname "$0")/../docker_open5gs"

# Stop all deployment compose files
COMPOSE_FILES=(
    "sa-deploy.yaml"
    "sa-vonr-deploy.yaml"
    "sa-vonr-opensips-ims-deploy.yaml"
    "4g-volte-deploy.yaml"
    "4g-volte-vowifi-deploy.yaml"
    "4g-volte-ocs-deploy.yaml"
    "4g-volte-opensips-ims-deploy.yaml"
    "4g-external-ims-deploy.yaml"
    "srsgnb_zmq.yaml"
    "srsenb_zmq.yaml"
    "srsue_zmq.yaml"
    "srsue_5g_zmq.yaml"
    "nr-gnb.yaml"
    "nr-ue.yaml"
)

for f in "${COMPOSE_FILES[@]}"; do
    if [[ -f "$f" ]]; then
        echo "Stopping: $f"
        docker compose -f "$f" down 2>/dev/null || true
    fi
done

echo ""
echo "✅ All deployments stopped."

if [[ "${1:-}" == "--all" ]]; then
    echo ""
    echo "Removing Docker volumes (subscriber data will be lost)..."
    docker volume prune -f 2>/dev/null || true
    echo "✅ Volumes removed."
fi

echo ""
echo "To redeploy, run one of:"
echo "  docker compose -f sa-deploy.yaml up -d          # 5G SA"
echo "  docker compose -f 4g-volte-deploy.yaml up -d    # 4G VoLTE"
