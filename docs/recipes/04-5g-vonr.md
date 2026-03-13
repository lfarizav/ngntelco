# Recipe 04: 5G VoNR (Voice over New Radio)

**Complexity:** ⭐⭐ Medium · **Time:** 10 minutes · **Containers:** 18+

Deploy a 5G Standalone core with IMS for native 5G voice calling (VoNR).

## Architecture

```
  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐
  │ NRF │ │ UDM │ │ UDR │ │AUSF │ │ PCF │
  └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘
     │       │       │       │       │
  ═══╪═══════╪═══════╪═══════╪═══════╪═══════ SBI Bus
     │       │
  ┌──┴──┐ ┌──┴──┐                     ┌──────┐
  │ SCP │ │ AMF │──── N2 ─────────────│ gNB  │
  └─────┘ └──┬──┘                     └──┬───┘
             │                            │ NR-Uu
          ┌──┴──┐     ┌─────┐         ┌──┴───┐
          │ SMF │─N4─►│ UPF │─N6───►  │  UE  │
          └─────┘     └─────┘         └──┬───┘
                                         │ SIP
              ┌──────────── IMS ─────────┤
              │                          │
         ┌────┴───┐  ┌───────┐  ┌───────┴──┐  ┌───────┐
         │ P-CSCF │  │I-CSCF │  │  S-CSCF  │  │ PyHSS │
         └────┬───┘  └───────┘  └──────────┘  └───────┘
              │
         ┌────┴──────┐
         │ RTPEngine  │
         └────────────┘
```

## What's New (vs Recipe 03)

VoNR adds the IMS (IP Multimedia Subsystem) on top of the 5G SA core:
- **Same IMS stack** as VoLTE (Kamailio + PyHSS + RTPEngine)
- **Key difference**: UE connects to IMS via 5G PDU session (not EPS bearer)
- **QoS Flow**: Dedicated 5QI=1 flow for voice (guaranteed bitrate)

## Step-by-Step

### 1. Pull Docker Images

```bash
cd docker_open5gs

# Core + IMS images (same as VoLTE recipe)
docker pull ghcr.io/herlesupreeth/docker_open5gs:master
docker tag ghcr.io/herlesupreeth/docker_open5gs:master docker_open5gs

docker pull ghcr.io/herlesupreeth/docker_kamailio:master
docker tag ghcr.io/herlesupreeth/docker_kamailio:master docker_kamailio

docker pull ghcr.io/herlesupreeth/docker_pyhss:master
docker tag ghcr.io/herlesupreeth/docker_pyhss:master docker_pyhss

docker pull ghcr.io/herlesupreeth/docker_ueransim:master
docker tag ghcr.io/herlesupreeth/docker_ueransim:master docker_ueransim
```

### 2. Deploy the 5G VoNR Stack

```bash
docker compose -f sa-vonr-deploy.yaml up -d
```

### 3. Add a VoNR Subscriber

Same as VoLTE — provision in Open5GS + PyHSS:

```bash
# Open5GS subscriber with internet + ims APNs
docker exec -it mongo mongosh open5gs --eval '
  db.subscribers.insertOne({
    "imsi": "001010000000001",
    "security": {
      "k": "465B5CE8B199B49FAA5F0A2EE238A6BC",
      "opc": "E8ED289DEBA952E4283B54E88E6183CA",
      "amf": "8000"
    },
    "slice": [{ "sst": 1, "default_indicator": true,
      "session": [
        { "name": "internet", "type": 3,
          "qos": { "index": 9, "arp": { "priority_level": 8 }},
          "ambr": { "downlink": {"value": 1, "unit": 3}, "uplink": {"value": 1, "unit": 3}}
        },
        { "name": "ims", "type": 3,
          "qos": { "index": 5, "arp": { "priority_level": 1 }},
          "ambr": { "downlink": {"value": 1, "unit": 3}, "uplink": {"value": 1, "unit": 3}}
        }
      ]
    }]
  })
'
```

### 4. Start gNB + UE

```bash
docker compose -f nr-gnb.yaml up -d
docker compose -f nr-ue.yaml up -d
```

### 5. Verify VoNR

```bash
# Check 5G registration
docker logs amf 2>&1 | grep -i "registered"

# Check IMS registration over 5G
docker logs pcscf 2>&1 | grep -i "register"

# Check dedicated QoS flow for IMS
docker logs smf 2>&1 | grep -i "qos"

# Verify both PDU sessions (internet + ims)
docker logs smf 2>&1 | grep -i "pdu session"
```

## VoNR vs VoLTE

| Aspect | VoLTE (4G) | VoNR (5G) |
|--------|-----------|-----------|
| Bearer | Dedicated EPS bearer | QoS Flow (5QI=1) |
| Latency | ~50ms setup | ~20ms setup |
| Codec | AMR-WB (HD) | EVS (Super HD) |
| Fallback | CS Fallback (2G/3G) | EPS Fallback (4G) |
| Slicing | N/A | Voice on dedicated slice |

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| IMS PDU session fails | Missing `ims` APN | Add ims session to subscriber |
| No voice QoS | PCF policy missing | Check `docker logs pcf` |
| Registration timeout | DNS resolution | Verify IMS DNS container running |

## Cleanup

```bash
docker compose -f nr-ue.yaml down
docker compose -f nr-gnb.yaml down
docker compose -f sa-vonr-deploy.yaml down
```

---

**Previous:** [Recipe 03 — 5G SA](03-5g-sa.md)  
**Next:** [Recipe 05 — VoWiFi](05-vowifi.md) (WiFi calling)
