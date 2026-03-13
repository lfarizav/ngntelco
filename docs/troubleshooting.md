# Troubleshooting Guide

Common issues and battle-tested fixes from real deployments.

## Quick Diagnostic Commands

```bash
# Check all running containers
docker compose -f <deploy-file>.yaml ps

# View logs for a specific NF
docker logs <container-name> 2>&1 | tail -100

# Run the automated health check
./scripts/health-check.sh

# Check subscriber exists
docker exec mongo mongosh --quiet open5gs --eval 'db.subscribers.find({"imsi":"001010000000001"}).pretty()'
```

---

## Network Issues

### UE Cannot Attach

**Symptoms:** UE stays in "searching" or "no service" state.

1. **Subscriber not provisioned:**
   ```bash
   # Check if subscriber exists
   docker exec mongo mongosh --quiet open5gs --eval 'db.subscribers.countDocuments({"imsi":"001010000000001"})'
   # If 0, add it:
   ./scripts/add-subscriber.sh --imsi 001010000000001
   ```

2. **PLMN mismatch:**
   ```bash
   # Check .env
   grep -E "MCC|MNC" docker_open5gs/.env
   # Must be MCC=001, MNC=01 matching the SIM
   ```

3. **MME/AMF not accepting connections:**
   ```bash
   # 4G
   docker logs mme 2>&1 | grep -i "error\|reject\|fail"
   # 5G
   docker logs amf 2>&1 | grep -i "error\|reject\|fail"
   ```

### No Internet After Attach

**Symptoms:** UE gets IP but cannot ping external addresses.

1. **IP forwarding disabled:**
   ```bash
   cat /proc/sys/net/ipv4/ip_forward
   # If 0:
   sudo sysctl -w net.ipv4.ip_forward=1
   ```

2. **Missing NAT rule:**
   ```bash
   # Add MASQUERADE for UE subnet
   sudo iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -j MASQUERADE
   ```

3. **UPF TUN interface missing:**
   ```bash
   docker exec upf ip addr show ogstun
   # Should show 192.168.100.1/24
   ```

4. **DNS not resolving:**
   ```bash
   docker exec srsue nslookup google.com
   # If fails, check SMF DNS config in .env:
   grep SMF_DNS docker_open5gs/.env
   ```

### Containers Won't Start

1. **Port conflicts:**
   ```bash
   sudo lsof -i :27017  # MongoDB
   sudo lsof -i :9999   # WebUI
   sudo lsof -i :3868   # Diameter
   ```

2. **Docker network conflict:**
   ```bash
   docker network ls
   # Remove conflicting networks:
   docker network prune
   ```

3. **Image not pulled:**
   ```bash
   docker images | grep open5gs
   # If empty:
   docker pull ghcr.io/herlesupreeth/docker_open5gs:master
   docker tag ghcr.io/herlesupreeth/docker_open5gs:master docker_open5gs
   ```

---

## IMS / VoLTE Issues

### IMS Registration Fails

1. **DNS not resolving IMS domain:**
   ```bash
   docker exec dns nslookup ims.mnc001.mcc001.3gppnetwork.org
   ```

2. **Diameter connections not established:**
   ```bash
   docker logs icscf 2>&1 | grep -i "diameter"
   docker logs scscf 2>&1 | grep -i "diameter"
   ```

3. **PyHSS subscriber missing:**
   ```bash
   docker logs pyhss 2>&1 | grep -i "subscriber\|error"
   ```

### No Voice Audio

1. **RTPEngine not running:**
   ```bash
   docker logs rtpengine 2>&1 | head -20
   ```

2. **Firewall blocking RTP ports:**
   ```bash
   # RTP uses UDP ports 30000-40000 by default
   sudo iptables -L -n | grep -i "30000\|udp"
   ```

---

## VoWiFi Issues

### ePDG Not Discovered

Phone can't find the ePDG for WiFi calling.

```bash
# DNS must resolve ePDG FQDN
nslookup epdg.epc.mnc001.mcc001.pub.3gppnetwork.org <docker-host-ip>
```

**Fix:** Set the phone's WiFi DNS server to the Docker host IP.

### IKEv2 Authentication Fails

```bash
# Check ePDG logs
docker logs osmoepdg 2>&1 | grep -i "ike\|eap\|auth"

# Verify SWx Diameter connection
docker logs osmoepdg 2>&1 | grep -i "diameter\|swx"
```

**Common cause:** K/OPc in HSS doesn't match SIM credentials.

### IPsec Tunnel Drops

```bash
# List active SAs
docker exec osmoepdg swanctl --list-sas

# Check for rekeying issues
docker logs osmoepdg 2>&1 | grep -i "rekey\|timeout\|expire"
```

---

## Performance Issues

### Slow Data Rate

1. **Check UPF CPU usage:**
   ```bash
   docker stats upf --no-stream
   ```

2. **Check AMBR settings:**
   ```bash
   docker exec mongo mongosh --quiet open5gs --eval '
     db.subscribers.find({"imsi":"001010000000001"}, {"slice.session.ambr":1}).pretty()
   '
   ```

3. **Increase AMBR:**
   ```bash
   docker exec mongo mongosh --quiet open5gs --eval '
     db.subscribers.updateOne(
       {"imsi":"001010000000001"},
       {$set: {"slice.0.session.0.ambr.downlink": {"value": 100, "unit": 3},
               "slice.0.session.0.ambr.uplink": {"value": 50, "unit": 3}}}
     )
   '
   ```

---

## Getting Help

1. Check the [Open5GS documentation](https://open5gs.org/open5gs/docs/)
2. Join the [Open5GS Discord](https://discord.gg/GreNkuc)
3. Open an [issue on this repo](https://github.com/lfarizav/ngntelco/issues)
