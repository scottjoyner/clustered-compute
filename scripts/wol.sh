#!/usr/bin/env bash
# Wake a machine by MAC
set -euo pipefail
MAC="${1:-}"
BCAST="${2:-255.255.255.255}"
if [[ -z "$MAC" ]]; then echo "Usage: $0 <MAC> [broadcast_ip]"; exit 1; fi
python3 - <<PY
import socket, sys, binascii
mac = sys.argv[1].replace(":", "").replace("-", "")
data = b'FF'*6 + mac.encode() * 16
pkt = binascii.unhexlify(data)
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
s.sendto(pkt, (sys.argv[2], 9))
print("Magic packet sent to", sys.argv[1], "via", sys.argv[2])
PY
