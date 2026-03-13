# Recipe 02: 4G VoLTE (Voice over LTE)

**Complexity:** ⭐⭐ Medium · **Time:** 10 minutes · **Containers:** 17

Deploy a complete 4G network with IMS for HD voice calls over LTE.

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                          INTERNET                                 │
└─────────────────────────────┬─────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              │ SGi           │               │
        ┌─────┴────┐    ┌────┴─────┐    ┌────┴─────┐
        │ SMF/PGW  │    │   DNS    │    │ Osmo HLR │
        │ internet │    │  (IMS)   │    │   MSC    │
        └─────┬────┘    └──────────┘    │  (SMS)   │
              │ S5                      └──────────┘
        ┌─────┴────┐
        │   S-GW   │     ┌─────────── IMS ──────────┐
        └─────┬────┘     │                           │
              │ S1-U     │  P-CSCF ↔ I-CSCF ↔ S-CSCF│
        ┌─────┴────┐     │     ↕         ↕          │
        │  eNodeB  │     │ RTPEngine   PyHSS        │
        └─────┬────┘     └───────────────────────────┘
              │ LTE-Uu
        ┌─────┴────┐
        │    UE    │ ── SIP (VoLTE) ──→ P-CSCF
        └──────────┘

  MME ←─ S6a ─→ HSS     PCRF ←─ Gx ─→ SMF
```

## What's New (vs Recipe 01)

| Component | Purpose |
|-----------|---------|
| P-CSCF (Kamailio) | Proxy-Call Session Control — entry point for IMS |
| I-CSCF (Kamailio) | Interrogating-CSCF — routes to correct S-CSCF |
| S-CSCF (Kamailio) | Serving-CSCF — SIP registrar and call control |
| PyHSS | IMS subscriber database (Diameter Cx/Sh) |
| RTPEngine | Media relay for voice packets (RTP) |
| DNS | IMS discovery (ims.mnc001.mcc001.3gppnetwork.org) |
| OsmoHLR + OsmoMSC | SMS over SGs interface |

## Step-by-Step

### 1. Pull Docker Images

```bash
cd docker_open5gs

docker pull ghcr.io/herlesupreeth/docker_open5gs:master
docker tag ghcr.io/herlesupreeth/docker_open5gs:master docker_open5gs

docker pull ghcr.io/herlesupreeth/docker_kamailio:master
docker tag ghcr.io/herlesupreeth/docker_kamailio:master docker_kamailio

docker pull ghcr.io/herlesupreeth/docker_pyhss:master
docker tag ghcr.io/herlesupreeth/docker_pyhss:master docker_pyhss

docker pull ghcr.io/herlesupreeth/docker_srslte:master
docker tag ghcr.io/herlesupreeth/docker_srslte:master docker_srslte
```

### 2. Deploy the Full VoLTE Stack

```bash
docker compose -f 4g-volte-deploy.yaml up -d
```

This starts the EPC core + IMS + DNS + SMS subsystem (17 containers).

### 3. Add a VoLTE Subscriber

You need to provision in **3 places**: Open5GS HSS, PyHSS (IMS), and OsmoHLR (SMS).

**a) Open5GS HSS** — via WebUI (`http://localhost:9999`):
- IMSI: `001010000000001`
- K / OPc: (same as Recipe 01)
- APN: `internet` + `ims` (add second APN for IMS bearer)

**b) PyHSS** — IMS subscriber:
```bash
# The PyHSS container auto-provisions from its config
# Check logs to verify:
docker logs pyhss 2>&1 | grep "subscriber"
```

**c) OsmoHLR** — SMS subscriber:
```bash
docker exec -it osmohlr telnet localhost 4258
> subscriber imsi 001010000000001 create
> subscriber imsi 001010000000001 update msisdn 0000000001
> exit
```

### 4. Start eNB + UE

```bash
docker compose -f srsenb_zmq.yaml up -d
docker compose -f srsue_zmq.yaml up -d
```

### 5. Verify VoLTE

```bash
# Check IMS registration
docker logs pcscf 2>&1 | grep -i "register"

# Check Diameter connectivity (HSS ↔ IMS)
docker logs icscf 2>&1 | grep -i "diameter"

# Check IMS DNS resolution
docker exec dns nslookup ims.mnc001.mcc001.3gppnetwork.org

# Check RTPEngine is ready
docker logs rtpengine 2>&1 | head -20
```

## How VoLTE Works

```
UE                    P-CSCF    I-CSCF    S-CSCF    PyHSS
│── REGISTER ────────►│         │         │         │
│                      │── UAR ─►│         │         │
│                      │         │── UAR ──►│         │
│                      │         │         │── MAR ──►│
│                      │         │         │◄── MAA ──│
│                      │◄── 401 Unauthorized ────────│
│◄── 401 ─────────────│         │         │         │
│── REGISTER (auth) ──►│────────►│────────►│────────►│
│◄── 200 OK ──────────│         │         │         │
│                      │         │         │         │
│── INVITE (call) ────►│────────►│────────►│         │
│                      │         │         │         │
│◄── 200 OK ──────────│         │         │         │
│── ACK ──────────────►│         │         │         │
│◄════ RTP (voice) ═══►│═══════►│ RTPEngine          │
```

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| IMS registration fails | DNS not resolving | Check `docker logs dns`, verify IMS domain |
| No voice audio | RTPEngine not running | `docker logs rtpengine`, restart if needed |
| Diameter connection down | Port conflict on 3868 | Check no other Diameter process running |
| SMS not delivered | OsmoHLR subscriber missing | Provision MSISDN in OsmoHLR |

## Cleanup

```bash
docker compose -f srsue_zmq.yaml down
docker compose -f srsenb_zmq.yaml down
docker compose -f 4g-volte-deploy.yaml down
```

---

**Previous:** [Recipe 01 — 4G LTE Basic](01-4g-lte-basic.md)  
**Next:** [Recipe 03 — 5G SA](03-5g-sa.md)
