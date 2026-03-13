# SIM Card Programming Guide

Program physical SIM cards (SysmoISIM-SJA2/SJA5) for Over-The-Air testing with real phones.

## Requirements

| Item | Purpose | Where to Buy |
|------|---------|--------------|
| SysmoISIM-SJA2 or SJA5 | Programmable USIM | [sysmocom shop](https://shop.sysmocom.de/) |
| Smart card reader | USB reader (e.g., Omnikey 3121) | Amazon/eBay |
| pySim | SIM programming tool | [Osmocom](https://osmocom.org/projects/pysim/wiki) |

## Install pySim

```bash
# Clone and install
git clone https://gitea.osmocom.org/sim-card/pysim.git
cd pysim
pip3 install -e .

# Verify
pySim-shell.py --help
```

## Program a SIM for Test Network

Our test PLMN is **001/01** (MCC=001, MNC=01).

### Basic Programming

```bash
# Launch pySim shell (card reader at port 0)
pySim-shell.py -p 0

# Set IMSI
select ADF.USIM
select EF.IMSI
update_binary 001010000000001

# Set MNC length (2 digits)
select EF.AD
update_binary 00000002

# Set HPLMN (Home PLMN)
select EF.EHPLMN
update_binary 00f110
```

### Enable 5G Services

Use the included script:

```bash
pySim-shell.py -p 0 -s docker_open5gs/sim/clone-vodafone-5g.script
```

Or manually:

```bash
pySim-shell.py -p 0

# Activate 5G services in EF.UST
select ADF.USIM
select EF.UST
ust_service_activate 96    # 5GS Mobility Management
ust_service_activate 122   # 5G Security Parameters
ust_service_activate 123   # Subscription concealing (SUCI)
ust_service_activate 124   # UAC Access Identities
ust_service_activate 125   # Control plane-based steering of UE in VPLMN
ust_service_activate 127   # 5GS Notification
ust_service_activate 129   # UE Policy delivery
ust_service_activate 130   # 5G ProSe
ust_service_activate 132   # NSSAA support
ust_service_activate 133   # 5G NSWO
ust_service_activate 134   # UCMF
ust_service_activate 135   # Trusted non-3GPP access
```

### Read All SIM Data

```bash
pySim-shell.py -p 0 -s docker_open5gs/sim/readall-5g.script
```

## Phone Configuration

### Pixel 6a / 7 / 8

1. Insert programmed SIM
2. Settings → Network & Internet → SIMs
3. Preferred network type: **LTE/NR** (or LTE for 4G only)
4. APN: Create new
   - Name: `ngntelco`
   - APN: `internet`
   - MCC: `001`
   - MNC: `01`
   - APN type: `default,supl,ims`

### Samsung Galaxy

1. Insert SIM
2. Settings → Connections → Mobile Networks
3. Network mode: **5G/LTE/3G/2G** or **LTE/3G/2G**
4. Access Point Names → Add:
   - Same settings as above

### Poco X6 / Xiaomi

1. Insert SIM
2. Settings → SIM Cards & Mobile Networks
3. Preferred network: **Prefer 5G** or **Prefer LTE**
4. APN: Add manually with same settings

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Card not detected | Reader not connected | Check `pcsc_scan` output |
| ADM pin rejected | Wrong ADM key | Use default `11111111` for sysmoISIM |
| Phone won't register | PLMN mismatch | Verify MCC/MNC matches .env and SIM |
| 5G not available | 5G services not activated | Run the 5G activation script |
| No IMS/VoLTE | Missing ims APN type | Add `ims` to APN types |
