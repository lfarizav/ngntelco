# Recipe 01: 4G LTE Basic

**Complexity:** ⭐ Easy · **Time:** 5 minutes · **Containers:** 8

Deploy a minimal 4G EPC core network with a simulated eNodeB and UE.

## Architecture

```
                    ┌──────────┐
                    │ Internet │
                    └────┬─────┘
                         │ SGi
                    ┌────┴─────┐        ┌──────────┐
                    │ SMF/PGW  │───Gx──►│   PCRF   │
                    └────┬─────┘        └──────────┘
                         │ S5/S8
                    ┌────┴─────┐
                    │   S-GW   │
                    └────┬─────┘
            S1-U         │         S1-MME
         ┌───────────────┤───────────────┐
         │               │               │
    ┌────┴─────┐    ┌────┴─────┐    ┌────┴─────┐
    │   MME    │    │  srsENB  │    │   HSS    │
    └──────────┘    └────┬─────┘    └──────────┘
                         │ LTE-Uu (ZMQ)
                    ┌────┴─────┐
                    │  srsUE   │
                    └──────────┘
```

## Components

| Container | Role | IP |
|-----------|------|----|
| mongo | Subscriber database | 172.22.0.2 |
| webui | Web-based subscriber management | 172.22.0.2:9999 |
| hss | Home Subscriber Server | 172.22.0.3 |
| mme | Mobility Management Entity | 172.22.0.9 |
| sgwc | Serving Gateway — Control Plane | 172.22.0.5 |
| sgwu | Serving Gateway — User Plane | 172.22.0.6 |
| smf | Session Management (PGW-C) | 172.22.0.7 |
| upf | User Plane Function (PGW-U) | 172.22.0.8 |

## Step-by-Step

### 1. Pull Docker Images

```bash
cd docker_open5gs

docker pull ghcr.io/herlesupreeth/docker_open5gs:master
docker tag ghcr.io/herlesupreeth/docker_open5gs:master docker_open5gs

docker pull ghcr.io/herlesupreeth/docker_srslte:master
docker tag ghcr.io/herlesupreeth/docker_srslte:master docker_srslte
```

### 2. Deploy the 4G Core

```bash
docker compose -f 4g-volte-deploy.yaml up -d mongo webui hss pcrf mme sgwc sgwu smf upf
```

### 3. Add a Test Subscriber

Open `http://localhost:9999` in your browser (admin / 1423), then:
- Click **Subscriber** → **+**
- Set IMSI: `001010000000001`
- Set K: `465B5CE8B199B49FAA5F0A2EE238A6BC`
- Set OPc: `E8ED289DEBA952E4283B54E88E6183CA`
- Click **Save**

Or via MongoDB:

```bash
docker exec -it mongo mongosh open5gs --eval '
  db.subscribers.insertOne({
    "imsi": "001010000000001",
    "security": {
      "k": "465B5CE8B199B49FAA5F0A2EE238A6BC",
      "opc": "E8ED289DEBA952E4283B54E88E6183CA",
      "amf": "8000"
    },
    "slice": [{ "sst": 1, "default_indicator": true,
      "session": [{ "name": "internet", "type": 3,
        "qos": { "index": 9, "arp": { "priority_level": 8 }},
        "ambr": { "downlink": {"value": 1, "unit": 3}, "uplink": {"value": 1, "unit": 3}}
      }]
    }]
  })
'
```

### 4. Start the Simulated eNB + UE

```bash
docker compose -f srsenb_zmq.yaml up -d
docker compose -f srsue_zmq.yaml up -d
```

### 5. Verify

```bash
# Check UE got an IP address
docker exec srsue ip addr show tun_srsue

# Test internet connectivity
docker exec srsue ping -c 3 8.8.8.8

# Check MME logs for successful attach
docker logs mme 2>&1 | grep -i "attach"
```

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| UE fails to attach | Subscriber not provisioned | Add subscriber via WebUI |
| No internet after attach | IP forwarding disabled | `sudo sysctl -w net.ipv4.ip_forward=1` |
| No internet after attach | Missing NAT rule | `sudo iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -j MASQUERADE` |
| Containers won't start | Port conflict | `docker compose down` first, check `docker ps` |

## Cleanup

```bash
docker compose -f srsue_zmq.yaml down
docker compose -f srsenb_zmq.yaml down
docker compose -f 4g-volte-deploy.yaml down
```

---

**Next:** [Recipe 02 — 4G VoLTE](02-4g-volte.md) (add voice calling)
