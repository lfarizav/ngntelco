# Architecture Reference

This directory contains reference diagrams and explanations of the 3GPP architectures deployed in this project.

## Network Architectures

### 4G LTE (EPC)

The Evolved Packet Core (EPC) is the 4G core network defined in 3GPP TS 23.401.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          4G EPC Architecture                            │
│                                                                         │
│  ┌───────┐    S6a     ┌───────┐    S11     ┌───────┐    S5/S8   ┌────┐ │
│  │  HSS  │◄──────────►│  MME  │◄──────────►│ S-GW  │◄─────────►│P-GW│ │
│  └───────┘  Diameter   └───┬───┘   GTPv2-C  └───┬───┘   GTPv2   └─┬──┘ │
│                            │ S1-MME              │ S1-U             │SGi │
│                            │ (SCTP)              │ (GTP-U)          │    │
│                       ┌────┴────┐           ┌────┘            ┌────┴──┐ │
│                       │  eNodeB │───────────┘                 │Internet│ │
│                       └────┬────┘                             └───────┘ │
│                            │ LTE-Uu                                     │
│                       ┌────┴────┐                                       │
│                       │   UE    │                                       │
│                       └─────────┘                                       │
│                                                                         │
│  PCRF ←─── Gx (Diameter) ───→ P-GW    (Policy & Charging)             │
└─────────────────────────────────────────────────────────────────────────┘
```

**Key interfaces:**
| Interface | Protocol | Purpose |
|-----------|----------|---------|
| S1-MME | SCTP/S1AP | Control plane: attach, handover, paging |
| S1-U | GTP-U | User plane: UE data tunneled to S-GW |
| S6a | Diameter | MME ↔ HSS: authentication, subscriber profiles |
| S5/S8 | GTPv2 | S-GW ↔ P-GW: bearer management |
| S11 | GTPv2-C | MME ↔ S-GW: session management |
| Gx | Diameter | P-GW ↔ PCRF: QoS policies |
| SGi | IP | P-GW ↔ Internet/IMS |

---

### 5G SA (SBA)

The 5G System (5GS) uses a Service-Based Architecture defined in 3GPP TS 23.501.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     5G Service-Based Architecture                       │
│                                                                         │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐   │
│  │ NRF │ │ UDM │ │ UDR │ │AUSF │ │ PCF │ │ NSSF│ │ BSF │ │ SCP │   │
│  └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘   │
│     │       │       │       │       │       │       │       │         │
│  ═══╪═══════╪═══════╪═══════╪═══════╪═══════╪═══════╪═══════╪═══════ │
│                    HTTP/2 Service-Based Interface (SBI)                 │
│  ════════════════════╪═══════╪════════════════════════════════════════ │
│                      │       │                                         │
│                   ┌──┴──┐ ┌──┴──┐                                     │
│                   │ AMF │ │ SMF │                                     │
│                   └──┬──┘ └──┬──┘                                     │
│               N2     │       │ N4 (PFCP)                              │
│                   ┌──┴──┐ ┌──┴──┐                                     │
│                   │ gNB │ │ UPF │─── N6 ──→ Internet                  │
│                   └──┬──┘ └─────┘                                     │
│               NR-Uu  │                                                 │
│                   ┌──┴──┐                                              │
│                   │ UE  │                                              │
│                   └─────┘                                              │
└─────────────────────────────────────────────────────────────────────────┘
```

**Key differences from 4G:**
| Aspect | 4G EPC | 5G SBA |
|--------|--------|---------|
| Design | Point-to-point | Service-based (microservices) |
| Protocol | Diameter + GTPv2-C | HTTP/2 + JSON |
| Discovery | Static | Dynamic via NRF |
| CP-UP | Partial (CUPS) | Full separation (SMF/UPF) |
| Slicing | N/A | Native (S-NSSAI = SST + SD) |
| Auth | EPS-AKA | 5G-AKA + EAP-AKA' |
| Identity | IMSI (cleartext) | SUCI (encrypted) → SUPI |

---

### IMS (IP Multimedia Subsystem)

The IMS provides voice (VoLTE/VoNR), video, and messaging services (3GPP TS 23.228).

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         IMS Architecture                                │
│                                                                         │
│  UE ──SIP──► ┌────────┐ ──SIP──► ┌────────┐ ──SIP──► ┌────────┐      │
│              │ P-CSCF │          │ I-CSCF │          │ S-CSCF │      │
│              └────┬───┘          └────────┘          └────┬───┘      │
│                   │                                       │           │
│                   │                                  Cx (Diameter)    │
│                   │                                       │           │
│              ┌────┴──────┐                           ┌────┴───┐      │
│              │ RTPEngine │                           │ PyHSS  │      │
│              │  (media)  │                           │ (IMS DB)│      │
│              └───────────┘                           └────────┘      │
│                                                                       │
│  Voice Call Flow:                                                     │
│  UE-A → INVITE → P-CSCF → I-CSCF → S-CSCF → I-CSCF → P-CSCF → UE-B│
│  UE-A ←══════════════ RTP (media) ═══════════════════════════════► UE-B│
└─────────────────────────────────────────────────────────────────────────┘
```

**CSCF roles:**
| Function | Full Name | Role |
|----------|-----------|------|
| P-CSCF | Proxy-CSCF | First contact point, SIP proxy, IPsec with UE |
| I-CSCF | Interrogating-CSCF | Routes registration to correct S-CSCF |
| S-CSCF | Serving-CSCF | SIP registrar, call routing, service triggers |
| PyHSS | IMS HSS | Subscriber profiles, authentication vectors (Cx) |
| RTPEngine | Media Proxy | RTP relay, codec transcoding, SRTP |

---

### VoWiFi (WiFi Calling)

Non-3GPP access via ePDG (3GPP TS 23.402).

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       VoWiFi Architecture                               │
│                                                                         │
│  ┌──────┐                    ┌───────┐                    ┌──────┐     │
│  │  UE  │── WiFi ── SWu ───►│ ePDG  │── S2b (GTP) ──────►│ P-GW │     │
│  └──────┘    IPsec/IKEv2    └───┬───┘                    └──┬───┘     │
│                                  │                           │         │
│                             SWx  │ (Diameter)                │ SGi     │
│                                  │                           │         │
│                             ┌────┴───┐                  ┌────┴───┐    │
│                             │  HSS   │                  │  IMS   │    │
│                             └────────┘                  └────────┘    │
│                                                                       │
│  Authentication: EAP-AKA (same SIM credentials as cellular)          │
│  Encryption: IPsec ESP (WiFi to ePDG tunnel)                         │
│  Voice: SIP/RTP over IPsec tunnel to IMS                             │
└─────────────────────────────────────────────────────────────────────────┘
```

**VoWiFi connection sequence:**
1. UE discovers ePDG via DNS (NAPTR → `epdg.epc.mnc001.mcc001.pub.3gppnetwork.org`)
2. IKEv2 SA established (EAP-AKA authentication against HSS)
3. IPsec child SA created (ESP tunnel for traffic)
4. P-GW assigns IP for `ims` APN
5. UE registers with P-CSCF (SIP over IPsec)
6. WiFi calling ready

---

## Network Slicing

```
┌─────────────────────────────────────────────────────────────┐
│                    Network Slicing                           │
│                                                              │
│  ┌─────────────────────────────────────┐                    │
│  │ Slice 1: eMBB (SST=1)              │                    │
│  │ High bandwidth, best-effort         │  ┌───┐  ┌─────┐   │
│  │ APN: internet │ UPF-1 ──────────────┤──│gNB│──│ AMF │   │
│  └─────────────────────────────────────┘  │   │  └──┬──┘   │
│                                           │   │     │      │
│  ┌─────────────────────────────────────┐  │   │  ┌──┴──┐   │
│  │ Slice 2: URLLC (SST=2)             │  │   │  │ SMF │   │
│  │ Ultra-reliable low-latency          │──│   │  └─────┘   │
│  │ APN: urllc │ UPF-2 (edge) ─────────┤  │   │             │
│  └─────────────────────────────────────┘  │   │  ┌──────┐  │
│                                           │   │  │ NSSF │  │
│  ┌─────────────────────────────────────┐  │   │  └──────┘  │
│  │ Slice 3: mMTC (SST=3)              │──│   │             │
│  │ Massive IoT, low power              │  └───┘             │
│  │ APN: iot │ UPF-3 ──────────────────┤                     │
│  └─────────────────────────────────────┘                    │
└─────────────────────────────────────────────────────────────┘
```

**Slice identifiers (S-NSSAI):**
| SST | Name | Use Case |
|-----|------|----------|
| 1 | eMBB | Broadband: video, browsing |
| 2 | URLLC | Critical: industrial control, autonomous driving |
| 3 | mMTC | IoT: sensors, meters, asset tracking |

---

## 3GPP Specification References

| Spec | Title | Architecture |
|------|-------|-------------|
| TS 23.401 | EPC Architecture | 4G core |
| TS 23.501 | 5G System Architecture | 5G core |
| TS 23.228 | IMS Architecture | VoLTE/VoNR |
| TS 23.402 | Non-3GPP Access | VoWiFi/ePDG |
| TS 29.244 | PFCP (N4) | SMF-UPF control |
| TS 29.500 | SBI Framework | 5G HTTP/2 APIs |
| TS 33.501 | 5G Security | 5G-AKA, SUCI |
| TS 28.541 | NRM | Network slicing |
