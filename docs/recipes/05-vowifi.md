# Recipe 05: VoWiFi (WiFi Calling)

**Complexity:** ⭐⭐⭐ Advanced · **Time:** 15 minutes · **Containers:** 20+

Deploy WiFi calling with ePDG (evolved Packet Data Gateway), IPsec tunnels, and EAP-AKA authentication.

## Architecture

```
                    ┌──────────┐
                    │ Internet │
                    └────┬─────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────┴─────┐   ┌─────┴────┐   ┌──────┴─────┐
    │ SMF/PGW  │   │ SMF/PGW  │   │    DNS     │
    │(internet)│   │  (ims)   │   │   (IMS)    │
    └────┬─────┘   └────┬─────┘   └────────────┘
         │              │
    ┌────┴─────┐   ┌────┴─────┐
    │   S-GW   │   │   S-GW   │     ┌── IMS ──────┐
    └────┬─────┘   └────┬─────┘     │P-CSCF S-CSCF│
         │              │           │I-CSCF PyHSS  │
         │         ┌────┴─────┐     │  RTPEngine   │
         │         │   ePDG   │◄────└──────────────┘
         │         │(Osmocom) │
         │         └────┬─────┘
         │              │ IPsec/IKEv2 (SWu)
    ┌────┴─────┐   ┌────┴─────┐
    │  eNodeB  │   │  WiFi AP │
    └────┬─────┘   └────┬─────┘
         │              │
    ┌────┴──────────────┴────┐
    │          UE             │
    │  LTE ←→ WiFi handover  │
    └─────────────────────────┘
```

## How VoWiFi Works

1. **UE connects to WiFi** → discovers ePDG via DNS (`epdg.epc.mnc001.mcc001.pub.3gppnetwork.org`)
2. **IKEv2 tunnel** → UE establishes IPsec SA with ePDG using EAP-AKA authentication
3. **SWu interface** → ePDG authenticates UE against HSS using Diameter SWx
4. **S2b interface** → ePDG establishes GTP tunnel to P-GW for IMS APN
5. **IMS registration** → UE registers with P-CSCF over the IPsec tunnel
6. **Voice calls** → SIP signaling + RTP media over WiFi

## What's New (vs Recipe 02)

| Component | Purpose |
|-----------|---------|
| osmoepdg | Evolved Packet Data Gateway — WiFi ↔ EPC bridge |
| strongswan | IKEv2/IPsec daemon inside ePDG |
| osmohlr | HSS for SWx authentication (EAP-AKA) |
| swu_client | Test client for SWu interface |

## Step-by-Step

### 1. Pull Docker Images

```bash
cd docker_open5gs

# All VoLTE images + ePDG
docker pull ghcr.io/herlesupreeth/docker_open5gs:master
docker tag ghcr.io/herlesupreeth/docker_open5gs:master docker_open5gs

docker pull ghcr.io/herlesupreeth/docker_kamailio:master
docker tag ghcr.io/herlesupreeth/docker_kamailio:master docker_kamailio

docker pull ghcr.io/herlesupreeth/docker_pyhss:master
docker tag ghcr.io/herlesupreeth/docker_pyhss:master docker_pyhss

docker pull ghcr.io/herlesupreeth/docker_osmoepdg:master
docker tag ghcr.io/herlesupreeth/docker_osmoepdg:master docker_osmoepdg
```

### 2. Deploy the VoWiFi Stack

```bash
docker compose -f 4g-volte-vowifi-deploy.yaml up -d
```

### 3. Provision Subscriber

Same as VoLTE (Recipe 02) — provision in Open5GS HSS + PyHSS + OsmoHLR.

Additionally, verify ePDG can authenticate the subscriber:

```bash
# Check ePDG Diameter connection to HSS
docker logs osmoepdg 2>&1 | grep -i "diameter"

# Verify SWx interface
docker logs osmoepdg 2>&1 | grep -i "swx"
```

### 4. Test WiFi Calling (with real phone)

**Requirements:**
- Programmable SIM (SysmoISIM-SJA2)
- Phone with VoWiFi support (Pixel 6a, Poco X6, Samsung Galaxy)
- WiFi network with access to Docker host

**Phone configuration:**
1. Insert programmed SIM card
2. Connect to WiFi network
3. Settings → Network → WiFi Calling → Enable
4. Set WiFi calling preference to "WiFi preferred"

**DNS configuration (on phone WiFi):**
- Set DNS server to Docker host IP
- This allows the phone to discover the ePDG

### 5. Verify

```bash
# Check ePDG for IKEv2 connections
docker logs osmoepdg 2>&1 | grep -i "ike"

# Check IPsec SAs established
docker exec osmoepdg swanctl --list-sas

# Check IMS registration via WiFi
docker logs pcscf 2>&1 | grep -i "register"

# Monitor WiFi calling status
docker logs smf 2>&1 | grep -i "ims"
```

## Tested Phones

| Phone | VoWiFi | Handover | Notes |
|-------|--------|----------|-------|
| Google Pixel 6a | ✅ | ✅ | Best compatibility |
| Poco X6 | ✅ | ⚠️ | Requires special APN config |
| Samsung Galaxy | ✅ | ✅ | May need carrier config override |

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| ePDG not discovered | DNS misconfigured | Phone DNS must point to Docker host |
| IKEv2 auth fails | EAP-AKA mismatch | Verify K/OPc in HSS matches SIM |
| IPsec tunnel drops | Timeout too short | Increase SA lifetime in strongswan config |
| No voice over WiFi | P-CSCF not on WiFi path | Verify P-CSCF routes via ePDG tunnel |

## Security Notes

- EAP-AKA uses SIM credentials — same security as cellular
- IPsec ESP encrypts all traffic in the WiFi-to-ePDG tunnel
- IMS signaling (SIP) is protected inside the IPsec tunnel

## Cleanup

```bash
docker compose -f 4g-volte-vowifi-deploy.yaml down
```

---

**Previous:** [Recipe 04 — 5G VoNR](04-5g-vonr.md)  
This is the most advanced recipe. For a simpler start, try [Recipe 01 — 4G LTE Basic](01-4g-lte-basic.md).
