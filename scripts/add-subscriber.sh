#!/usr/bin/env bash
# add-subscriber.sh — Add a subscriber to the Open5GS MongoDB
# Usage: ./scripts/add-subscriber.sh [--imsi IMSI] [--key K] [--opc OPC] [--apn APN] [--sst SST]

set -euo pipefail

# Defaults (test PLMN 001/01)
IMSI="${IMSI:-001010000000001}"
KEY="${KEY:-465B5CE8B199B49FAA5F0A2EE238A6BC}"
OPC="${OPC:-E8ED289DEBA952E4283B54E88E6183CA}"
AMF_VALUE="8000"
APN="${APN:-internet}"
SST="${SST:-1}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --imsi) IMSI="$2"; shift 2 ;;
        --key)  KEY="$2"; shift 2 ;;
        --opc)  OPC="$2"; shift 2 ;;
        --apn)  APN="$2"; shift 2 ;;
        --sst)  SST="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: $0 [--imsi IMSI] [--key K] [--opc OPC] [--apn APN] [--sst SST]"
            echo ""
            echo "Options:"
            echo "  --imsi  IMSI (default: 001010000000001)"
            echo "  --key   Authentication key K (default: test key)"
            echo "  --opc   OPc value (default: test OPc)"
            echo "  --apn   APN name (default: internet)"
            echo "  --sst   Slice/Service Type (default: 1 = eMBB)"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Validate IMSI format (15 digits)
if ! [[ "$IMSI" =~ ^[0-9]{15}$ ]]; then
    echo "Error: IMSI must be exactly 15 digits. Got: $IMSI"
    exit 1
fi

# Validate hex strings
if ! [[ "$KEY" =~ ^[0-9A-Fa-f]{32}$ ]]; then
    echo "Error: Key must be exactly 32 hex characters. Got: $KEY"
    exit 1
fi

if ! [[ "$OPC" =~ ^[0-9A-Fa-f]{32}$ ]]; then
    echo "Error: OPc must be exactly 32 hex characters. Got: $OPC"
    exit 1
fi

echo "Adding subscriber:"
echo "  IMSI: $IMSI"
echo "  Key:  $KEY"
echo "  OPc:  $OPC"
echo "  APN:  $APN"
echo "  SST:  $SST"
echo ""

# Check if mongo container is running
if ! docker ps --format '{{.Names}}' | grep -q '^mongo$'; then
    echo "Error: 'mongo' container is not running."
    echo "Start the core network first: docker compose -f sa-deploy.yaml up -d"
    exit 1
fi

# Check if subscriber already exists
EXISTING=$(docker exec mongo mongosh --quiet open5gs --eval "db.subscribers.countDocuments({\"imsi\":\"$IMSI\"})" 2>/dev/null || echo "0")
if [[ "$EXISTING" != "0" ]]; then
    echo "Warning: Subscriber $IMSI already exists. Updating..."
    docker exec mongo mongosh --quiet open5gs --eval "db.subscribers.deleteOne({\"imsi\":\"$IMSI\"})" > /dev/null
fi

# Insert subscriber
docker exec mongo mongosh --quiet open5gs --eval "
  db.subscribers.insertOne({
    \"imsi\": \"$IMSI\",
    \"security\": {
      \"k\": \"$KEY\",
      \"opc\": \"$OPC\",
      \"amf\": \"$AMF_VALUE\"
    },
    \"slice\": [{
      \"sst\": $SST,
      \"default_indicator\": true,
      \"session\": [{
        \"name\": \"$APN\",
        \"type\": 3,
        \"qos\": {
          \"index\": 9,
          \"arp\": {\"priority_level\": 8, \"pre_emption_capability\": 1, \"pre_emption_vulnerability\": 1}
        },
        \"ambr\": {
          \"downlink\": {\"value\": 1, \"unit\": 3},
          \"uplink\": {\"value\": 1, \"unit\": 3}
        }
      }]
    }]
  })
" > /dev/null

echo "✅ Subscriber $IMSI added successfully."
echo ""
echo "Verify: docker exec mongo mongosh --quiet open5gs --eval 'db.subscribers.find({\"imsi\":\"$IMSI\"}).pretty()'"
