# KubeCon Europe 2026 — Companion Materials

## Talk: Private 5G Networks with Kubernetes

**Speaker:** Luis Felipe Ariza Vesga  
**Event:** KubeCon + CloudNativeCon Europe 2026  

### Materials

| Resource | Link |
|----------|------|
| Slides (PDF) | [Coming soon] |
| Video Recording | [Coming soon] |
| Live Demo Recording | [Coming soon] |

### Follow Along

| Timestamp | Topic | Recipe |
|-----------|-------|--------|
| 00:00 | Introduction — Why private cellular? | — |
| 05:00 | 4G/5G Architecture explained | [Architecture docs](../docs/architecture/) |
| 12:00 | Live Demo — Deploy 5G SA | [Recipe 03](../docs/recipes/03-5g-sa.md) |
| 18:00 | VoLTE/VoNR — Voice calls | [Recipe 04](../docs/recipes/04-5g-vonr.md) |
| 22:00 | Over-The-Air with USRP | [OTA Guide](../docs/sim-programming.md) |
| 25:00 | Lessons from production | [Troubleshooting](../docs/troubleshooting.md) |
| 28:00 | Q&A | — |

### Try It Yourself

```bash
# Clone and deploy in 5 minutes
git clone https://github.com/lfarizav/ngntelco.git
cd ngntelco/docker_open5gs
docker pull ghcr.io/herlesupreeth/docker_open5gs:master && docker tag ghcr.io/herlesupreeth/docker_open5gs:master docker_open5gs
docker compose -f sa-deploy.yaml up -d
```

### Questions?

- GitHub Issues: https://github.com/lfarizav/ngntelco/issues
- LinkedIn: [Luis Felipe Ariza Vesga](https://linkedin.com/in/lfarizav)
