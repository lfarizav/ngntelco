#!/usr/bin/env bash
# health-check.sh — Verify deployment health for any recipe
# Usage: ./scripts/health-check.sh [4g|5g|volte|vonr|vowifi]

set -euo pipefail

RECIPE="${1:-auto}"
PASS=0
FAIL=0
WARN=0

green()  { echo -e "\033[32m✅ $1\033[0m"; ((PASS++)); }
red()    { echo -e "\033[31m❌ $1\033[0m"; ((FAIL++)); }
yellow() { echo -e "\033[33m⚠️  $1\033[0m"; ((WARN++)); }

echo "╔══════════════════════════════════════════╗"
echo "║   ngntelco — Deployment Health Check     ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Auto-detect deployment type
if [[ "$RECIPE" == "auto" ]]; then
    if docker ps --format '{{.Names}}' | grep -q '^osmoepdg$'; then
        RECIPE="vowifi"
    elif docker ps --format '{{.Names}}' | grep -q '^pcscf$' && docker ps --format '{{.Names}}' | grep -q '^nrf$'; then
        RECIPE="vonr"
    elif docker ps --format '{{.Names}}' | grep -q '^pcscf$'; then
        RECIPE="volte"
    elif docker ps --format '{{.Names}}' | grep -q '^nrf$'; then
        RECIPE="5g"
    elif docker ps --format '{{.Names}}' | grep -q '^mme$'; then
        RECIPE="4g"
    else
        echo "No deployment detected. Start a deployment first."
        exit 1
    fi
    echo "Auto-detected: $RECIPE"
fi

echo ""
echo "── Core Infrastructure ──"

# MongoDB
if docker ps --format '{{.Names}}' | grep -q '^mongo$'; then
    green "MongoDB is running"
    SUB_COUNT=$(docker exec mongo mongosh --quiet open5gs --eval 'db.subscribers.countDocuments()' 2>/dev/null || echo "0")
    if [[ "$SUB_COUNT" -gt 0 ]]; then
        green "Subscribers provisioned: $SUB_COUNT"
    else
        yellow "No subscribers provisioned — add one with scripts/add-subscriber.sh"
    fi
else
    red "MongoDB is NOT running"
fi

# WebUI
if docker ps --format '{{.Names}}' | grep -q '^webui$'; then
    green "WebUI is running (http://localhost:9999)"
else
    yellow "WebUI is not running"
fi

echo ""
echo "── Core Network Functions ──"

# 4G-specific checks
if [[ "$RECIPE" == "4g" || "$RECIPE" == "volte" || "$RECIPE" == "vowifi" ]]; then
    for nf in hss mme sgwc sgwu smf upf pcrf; do
        if docker ps --format '{{.Names}}' | grep -q "^${nf}$"; then
            green "$nf is running"
        else
            red "$nf is NOT running"
        fi
    done
fi

# 5G-specific checks
if [[ "$RECIPE" == "5g" || "$RECIPE" == "vonr" ]]; then
    for nf in nrf scp ausf udm udr amf smf upf pcf nssf bsf; do
        if docker ps --format '{{.Names}}' | grep -q "^${nf}$"; then
            green "$nf is running"
        else
            if [[ "$nf" == "bsf" || "$nf" == "scp" ]]; then
                yellow "$nf is not running (optional)"
            else
                red "$nf is NOT running"
            fi
        fi
    done
fi

# IMS checks
if [[ "$RECIPE" == "volte" || "$RECIPE" == "vonr" || "$RECIPE" == "vowifi" ]]; then
    echo ""
    echo "── IMS Subsystem ──"
    for nf in dns pcscf icscf scscf pyhss rtpengine; do
        if docker ps --format '{{.Names}}' | grep -q "^${nf}$"; then
            green "$nf is running"
        else
            red "$nf is NOT running"
        fi
    done
fi

# VoWiFi checks
if [[ "$RECIPE" == "vowifi" ]]; then
    echo ""
    echo "── VoWiFi (ePDG) ──"
    for nf in osmoepdg osmohlr; do
        if docker ps --format '{{.Names}}' | grep -q "^${nf}$"; then
            green "$nf is running"
        else
            red "$nf is NOT running"
        fi
    done
fi

# RAN checks
echo ""
echo "── Radio Access Network (RAN) ──"

ran_found=false
for ran in srsenb srsgnb nr-gnb ueransim-gnb; do
    if docker ps --format '{{.Names}}' | grep -q "^${ran}$"; then
        green "$ran is running"
        ran_found=true
    fi
done
if ! $ran_found; then
    yellow "No RAN simulator detected — start srsENB/srsGNB/UERANSIM"
fi

# UE checks
ue_found=false
for ue in srsue nr-ue ueransim-ue; do
    if docker ps --format '{{.Names}}' | grep -q "^${ue}$"; then
        green "$ue is running"
        ue_found=true
    fi
done
if ! $ue_found; then
    yellow "No UE simulator detected"
fi

# Network connectivity
echo ""
echo "── Network Connectivity ──"

if docker network ls --format '{{.Name}}' | grep -q 'open5gs'; then
    green "Docker network exists"
else
    yellow "Docker network not found (may use default name)"
fi

# IP forwarding
if [[ $(cat /proc/sys/net/ipv4/ip_forward) == "1" ]]; then
    green "IP forwarding is enabled"
else
    red "IP forwarding is DISABLED — run: sudo sysctl -w net.ipv4.ip_forward=1"
fi

# Summary
echo ""
echo "══════════════════════════════════════════"
echo "  Results: ✅ $PASS passed · ❌ $FAIL failed · ⚠️  $WARN warnings"
echo "══════════════════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
