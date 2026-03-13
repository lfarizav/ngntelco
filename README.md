<p align="center">
  <img src="docs/images/ngntelco-banner.png" alt="ngntelco" width="600"/>
</p>

<h1 align="center">ngntelco — Private Cellular Lab-in-a-Box</h1>

<p align="center">
  <strong>Deploy a complete 4G/5G private cellular network on your laptop in under 5 minutes.</strong><br/>
  KubeCon Europe 2026 Companion Repository
</p>

<p align="center">
  <a href="#-quickstart"><img src="https://img.shields.io/badge/-Quickstart-blue?style=for-the-badge" alt="Quickstart"/></a>
  <a href="#-watch-the-talk"><img src="https://img.shields.io/badge/-Watch%20Talk-red?style=for-the-badge" alt="Watch Talk"/></a>
  <a href="#-deployment-recipes"><img src="https://img.shields.io/badge/-Recipes-green?style=for-the-badge" alt="Recipes"/></a>
  <a href="docs/architecture/README.md"><img src="https://img.shields.io/badge/-Architecture-purple?style=for-the-badge" alt="Architecture"/></a>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-blue.svg" alt="License"/></a>
  <img src="https://img.shields.io/badge/open5gs-v2.7+-green.svg" alt="Open5GS"/>
  <img src="https://img.shields.io/badge/srsRAN-2024.2+-orange.svg" alt="srsRAN"/>
  <img src="https://img.shields.io/badge/tested-March%202026-brightgreen.svg" alt="Last Tested"/>
  <img src="https://img.shields.io/badge/3GPP-Rel.17-informational.svg" alt="3GPP"/>
</p>

---

## What is this?

This repository is a **curated, production-tested collection of deployment recipes** for building private 4G and 5G cellular networks using open-source software. Built by a [Golden Kubestronaut](https://www.credly.com/badges/kubestronaut) with a PhD in telecommunications who spent years reading 3GPP specifications — so you don't have to.

It wraps [herlesupreeth/docker_open5gs](https://github.com/herlesupreeth/docker_open5gs) with:

- **5 tested deployment recipes** — from basic 4G to full VoNR + VoWiFi
- **Architecture diagrams** — understand what you're deploying and why
- **Subscriber provisioning scripts** — add UEs, configure slices, set QoS
- **Monitoring dashboards** — Grafana + Prometheus out of the box
- **SIM programming guides** — program real SysmoISIM cards for OTA testing
- **Real-world troubleshooting** — battle-tested fixes from live deployments

> **No proprietary code.** Everything here is open-source and free to use.

---

## 🎬 Watch the Talk

| Event | Title | Links |
|-------|-------|-------|
| KubeCon EU 2026 | *Private 5G Networks with Kubernetes* | [📹 Video](#) · [📊 Slides](slides/kubecon-eu-2026/) |

> Timestamps: [00:00 Intro](#) · [05:00 Architecture](#) · [12:00 Live Demo](#) · [20:00 Lessons Learned](#) · [28:00 Q&A](#)

---

## 🚀 Quickstart

### Prerequisites

| Requirement | Minimum | Recommended |
|------------|---------|-------------|
| OS | Ubuntu 22.04+ | Ubuntu 24.04 |
| Docker | 22.0.5+ | Latest |
| Docker Compose | v2.14+ | Latest |
| RAM | 4 GB | 8 GB |
| CPU | 2 cores | 4 cores |
| Disk | 10 GB | 20 GB |

### Deploy a 5G SA Network (RF Simulated)

```bash
# 1. Clone the repo
git clone https://github.com/lfarizav/ngntelco.git && cd ngntelco

# 2. Pull pre-built images
cd docker_open5gs
docker pull ghcr.io/herlesupreeth/docker_open5gs:master
docker tag ghcr.io/herlesupreeth/docker_open5gs:master docker_open5gs
docker pull ghcr.io/herlesupreeth/docker_ueransim:master
docker tag ghcr.io/herlesupreeth/docker_ueransim:master docker_ueransim

# 3. Deploy the 5G SA core
docker compose -f sa-deploy.yaml up -d

# 4. Add a test subscriber
# (from inside the webui container or using the provisioning script)
../scripts/add-subscriber.sh --imsi 001010000000001 --key 465B5CE8B199B49FAA5F0A2EE238A6BC --opc E8ED289DEBA952E4283B54E88E6183CA

# 5. Start the simulated gNB + UE
docker compose -f srsgnb_zmq.yaml up -d
docker compose -f srsue_5g_zmq.yaml up -d

# 6. Verify connectivity
docker exec srsue ping -c 3 8.8.8.8
```

**That's it.** You have a working 5G SA network. 🎉

For more scenarios, see [Deployment Recipes](#-deployment-recipes).

---

## 📋 Deployment Recipes

Each recipe is a tested, end-to-end deployment guide with architecture diagrams, step-by-step instructions, and verification commands.

| # | Recipe | Description | Complexity | Time |
|---|--------|-------------|-----------|------|
| 1 | [**4G LTE Basic**](docs/recipes/01-4g-lte-basic.md) | EPC core + srsENB simulator | ⭐ | 5 min |
| 2 | [**4G VoLTE**](docs/recipes/02-4g-volte.md) | Full EPC + IMS (Kamailio) + voice calls | ⭐⭐ | 10 min |
| 3 | [**5G SA**](docs/recipes/03-5g-sa.md) | 5G Standalone core + UERANSIM | ⭐ | 5 min |
| 4 | [**5G VoNR**](docs/recipes/04-5g-vonr.md) | 5G + Voice over NR + IMS | ⭐⭐ | 10 min |
| 5 | [**VoWiFi**](docs/recipes/05-vowifi.md) | WiFi calling with ePDG + IPsec | ⭐⭐⭐ | 15 min |

### Recipe Format

Every recipe includes:
1. **Architecture diagram** — what you're deploying
2. **Components list** — every container and its role
3. **Step-by-step instructions** — copy-pasteable commands
4. **Subscriber provisioning** — add test UEs
5. **Verification** — prove it works
6. **Troubleshooting** — common issues and fixes

---

## 🏗️ Architecture

### 4G EPC Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
└───────────────────────────┬─────────────────────────────────┘
                            │ SGi
                    ┌───────┴───────┐
                    │    P-GW/SMF   │───── PCRF (Policy)
                    │  172.22.0.7   │
                    └───────┬───────┘
                            │ S5/S8
                    ┌───────┴───────┐
                    │     S-GW      │
                    │  172.22.0.5/6 │
                    └───────┬───────┘
                            │ S1-U (GTP-U)
            ┌───────────────┼───────────────┐
            │               │               │
     ┌──────┴──────┐ ┌──────┴──────┐ ┌──────┴──────┐
     │   eNodeB 1  │ │   eNodeB 2  │ │   eNodeB 3  │
     └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
            │ LTE-Uu        │               │
     ┌──────┴──────┐ ┌──────┴──────┐ ┌──────┴──────┐
     │    UE 1     │ │    UE 2     │ │    UE 3     │
     └─────────────┘ └─────────────┘ └─────────────┘

  MME (172.22.0.9) ←──S1-MME──→ eNodeB
  MME ←──S6a (Diameter)──→ HSS (172.22.0.3)
```

### 5G SBA Architecture

```
  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐
  │ NRF │ │ UDM │ │ UDR │ │AUSF │ │ PCF │ │ NSSF│ │ BSF │
  └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘
     │       │       │       │       │       │       │
  ═══╪═══════╪═══════╪═══════╪═══════╪═══════╪═══════╪═══ SBI Bus
     │       │       │       │       │       │       │
  ┌──┴──┐ ┌──┴──┐                          ┌──┴──┐
  │ SCP │ │ AMF │──────── N2 ──────────────│ gNB │
  └─────┘ └──┬──┘                          └──┬──┘
             │                                │ NR-Uu
          ┌──┴──┐        ┌─────┐           ┌──┴──┐
          │ SMF │── N4 ──│ UPF │── N6 ──→  │ UE  │
          └─────┘        └─────┘  Internet  └─────┘
```

### IMS Architecture (VoLTE/VoNR)

```
  ┌──────────┐    SIP     ┌──────────┐   Diameter   ┌──────────┐
  │  P-CSCF  │◄──────────►│  S-CSCF  │◄────────────►│  PyHSS   │
  │(Kamailio)│            │(Kamailio)│              │          │
  └────┬─────┘            └────┬─────┘              └──────────┘
       │                       │
       │ SIP            ┌──────┴─────┐
       │                │   I-CSCF   │
       │                │(Kamailio)  │
       │                └────────────┘
       │
  ┌────┴─────┐    RTP    ┌──────────┐
  │    UE    │◄─────────►│RTPEngine │
  │ (Phone)  │           │ (Media)  │
  └──────────┘           └──────────┘
```

More diagrams: [docs/architecture/](docs/architecture/)

---

## 🔧 Subscriber Management

### Using the WebUI

Access the Open5GS WebUI at `http://localhost:9999` after deployment.

- Default credentials: `admin` / `1423`

### Using MongoDB Directly

```bash
# Add a basic 5G subscriber
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

### Using the Provisioning Script

```bash
# Add subscriber with default settings
./scripts/add-subscriber.sh --imsi 001010000000001

# Add subscriber with custom APN and slice
./scripts/add-subscriber.sh \
  --imsi 001010000000002 \
  --key 465B5CE8B199B49FAA5F0A2EE238A6BC \
  --opc E8ED289DEBA952E4283B54E88E6183CA \
  --apn internet \
  --sst 1
```

---

## 📊 Monitoring

### Grafana Dashboards

After deploying with monitoring enabled:

- **Grafana**: `http://localhost:3000` (admin/admin)
- **Prometheus**: `http://localhost:9090`

Available dashboards:
- **Open5GS Core** — UE sessions, GTP tunnels, NF status
- **RAN Metrics** — RSRP, SINR, throughput per UE
- **IMS Health** — SIP registrations, call attempts, RTP quality

### Quick Health Check

```bash
# Verify all containers are running
docker compose -f sa-deploy.yaml ps

# Check AMF logs for UE registration
docker logs amf 2>&1 | grep "UE Context"

# Check UPF for active PDU sessions
docker logs upf 2>&1 | grep "GTP-U"

# Verify UE has internet connectivity
docker exec srsue ping -c 3 8.8.8.8
```

---

## 📡 Over-The-Air (OTA) Testing

### Supported SDR Hardware

| Hardware | 4G (eNB) | 5G (gNB) | Approx. Price |
|----------|----------|----------|---------------|
| Ettus USRP B210 | ✅ | ✅ | ~$1,500 |
| LibreSDR (B210 clone) | ✅ | ✅ | ~$350 |
| LimeSDR Mini v1.3 | ✅ | ❌ | ~$200 |
| LimeSDR-USB | ✅ | ❌ | ~$300 |

### SIM Card Programming

To test with real phones, you need programmable SIM cards (SysmoISIM-SJA2/SJA5).

```bash
# Install pySim
pip3 install pysim

# Program a SIM for your test network (MCC=001, MNC=01)
pySim-shell.py -p 0
> select ADF.USIM
> update_binary EF.IMSI 001010000000001
> update_binary EF.AD 00000002  # MNC length = 2
```

See [docs/sim-programming.md](docs/sim-programming.md) for detailed SIM programming guides.

---

## 📁 Repository Structure

```
ngntelco/
├── README.md                 ← You are here
├── docker_open5gs/           ← Core network containers (herlesupreeth fork)
│   ├── sa-deploy.yaml        ← 5G SA deployment
│   ├── 4g-volte-deploy.yaml  ← 4G VoLTE deployment
│   ├── sa-vonr-deploy.yaml   ← 5G VoNR deployment
│   ├── 4g-volte-vowifi-deploy.yaml ← VoWiFi deployment
│   ├── .env                  ← Network configuration (IPs, MCC/MNC)
│   ├── grafana/              ← Monitoring dashboards
│   └── sim/                  ← SIM programming scripts
├── docs/
│   ├── architecture/         ← 3GPP architecture diagrams
│   ├── recipes/              ← Step-by-step deployment guides
│   ├── sim-programming.md    ← SIM card programming guide
│   └── troubleshooting.md    ← Common issues and fixes
├── scripts/
│   ├── add-subscriber.sh     ← Provision test subscribers
│   ├── health-check.sh       ← Verify deployment health
│   └── cleanup.sh            ← Remove all containers/networks
├── slides/
│   └── kubecon-eu-2026/      ← Presentation materials
└── LICENSE
```

---

## 🔬 Tested Environments

| Component | Version | Status |
|-----------|---------|--------|
| Open5GS | 2.7.x | ✅ Verified |
| srsRAN_4G | 23.11+ | ✅ Verified |
| srsRAN_Project | 24.04+ | ✅ Verified |
| UERANSIM | 3.2.6+ | ✅ Verified |
| Kamailio (IMS) | 5.8.x | ✅ Verified |
| Docker | 24.x+ | ✅ Verified |
| Docker Compose | v2.20+ | ✅ Verified |
| Ubuntu | 22.04 / 24.04 | ✅ Verified |

---

## 🛠️ Troubleshooting

<details>
<summary><strong>UE cannot attach to the network</strong></summary>

1. Check subscriber is provisioned: `docker exec mongo mongosh open5gs --eval 'db.subscribers.find({"imsi":"001010000000001"}).pretty()'`
2. Check AMF/MME logs: `docker logs amf 2>&1 | tail -50`
3. Verify PLMN matches: MCC=001, MNC=01 in both `.env` and SIM
4. Ensure all NFs are running: `docker compose -f sa-deploy.yaml ps`
</details>

<details>
<summary><strong>No internet after attach</strong></summary>

1. Check UPF TUN interface: `docker exec upf ip addr show ogstun`
2. Enable IP forwarding: `sudo sysctl -w net.ipv4.ip_forward=1`
3. Add NAT rule: `sudo iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o <host-interface> -j MASQUERADE`
4. Verify DNS: `docker exec srsue nslookup google.com`
</details>

<details>
<summary><strong>VoLTE registration fails</strong></summary>

1. Check IMS DNS: `docker exec dns nslookup ims.mnc001.mcc001.3gppnetwork.org`
2. Check P-CSCF logs: `docker logs pcscf 2>&1 | grep "REGISTER"`
3. Verify PyHSS has the IMS subscriber: check PyHSS web interface
4. Ensure Diameter connections are established: `docker logs icscf 2>&1 | grep "Diameter"`
</details>

<details>
<summary><strong>Docker Compose fails to start</strong></summary>

1. Ensure Docker subnet doesn't conflict: check `docker network ls` and `.env` `TEST_NETWORK`
2. Free port conflicts: `sudo lsof -i :27017` (MongoDB), `sudo lsof -i :9999` (WebUI)
3. Pull latest images: `docker pull ghcr.io/herlesupreeth/docker_open5gs:master`
</details>

See [docs/troubleshooting.md](docs/troubleshooting.md) for the complete troubleshooting guide.

---

## 🤝 Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Good first contributions:**
- Add a new deployment recipe
- Improve documentation or diagrams
- Add test scenarios
- Report issues with specific Docker/OS versions

---

## 📚 Learn More

### 3GPP Specifications (Free Access)

| Spec | Title | Relevance |
|------|-------|-----------|
| [TS 23.401](https://www.3gpp.org/ftp/Specs/archive/23_series/23.401/) | EPC Architecture | 4G core network |
| [TS 23.501](https://www.3gpp.org/ftp/Specs/archive/23_series/23.501/) | 5G System Architecture | 5G core network |
| [TS 23.228](https://www.3gpp.org/ftp/Specs/archive/23_series/23.228/) | IMS Architecture | VoLTE/VoNR |
| [TS 23.402](https://www.3gpp.org/ftp/Specs/archive/23_series/23.402/) | Non-3GPP Access | VoWiFi/ePDG |
| [TS 28.541](https://www.3gpp.org/ftp/Specs/archive/28_series/28.541/) | Network Resource Model | Network slicing |

### Open-Source Projects

- [Open5GS](https://open5gs.org/) — 4G/5G core network
- [srsRAN](https://www.srsran.com/) — 4G/5G RAN
- [UERANSIM](https://github.com/aligungr/UERANSIM) — 5G UE/gNB simulator
- [Kamailio](https://www.kamailio.org/) — SIP server (IMS)
- [pySim](https://osmocom.org/projects/pysim/wiki) — SIM programming

---

## 📜 License

This project is licensed under the GPL-3.0 License — see the [LICENSE](LICENSE) file for details.

The `docker_open5gs/` directory contains work by [herlesupreeth](https://github.com/herlesupreeth/docker_open5gs) under its own license.

---

## 👤 Author

**Luis Felipe Ariza Vesga** — [Kubestronaut](https://www.credly.com/users/lfarizav) · PhD in Telecommunications

> *I spent years reading 3GPP specifications and building private cellular networks. This repo packages that knowledge so you can deploy one in 5 minutes.*

---

<p align="center">
  <sub>Built with ❤️ for the cloud-native telecom community</sub><br/>
  <sub>⭐ Star this repo if you find it useful — it helps others discover it</sub>
</p>
