#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-}"
if [[ -z "$MODE" ]]; then
  echo "Usage: $0 [offgrid|ongrid]"
  exit 1
fi

PI_HOST=${PI_HOST:-"gateway"}           # Raspberry Pi hostname/IP
GPU_NODE=${GPU_NODE:-"zeus"}            # Deathstar k8s node name
KUBECONFIG=${KUBECONFIG:-"$HOME/.kube/config"}

if [[ "$MODE" == "offgrid" ]]; then
  echo "[*] Switching to OFF-GRID mode..."
  # Pi: enable DHCP (dnsmasq) and set Unbound as upstream
  ssh "$PI_HOST" "sudo systemctl enable --now dnsmasq unbound; sudo systemctl stop isc-dhcp-server || true"
  # Kubernetes: cordon GPU node
  kubectl cordon "$GPU_NODE" || true
  # Observability: reduce scrape interval (example: swap ConfigMap)
  kubectl -n infra annotate cm prometheus-config mode=offgrid --overwrite || true

elif [[ "$MODE" == "ongrid" ]]; then
  echo "[*] Switching to ON-GRID mode..."
  # Pi: disable DHCP; upstream to public DNS
  ssh "$PI_HOST" "sudo systemctl disable --now dnsmasq || true"
  # Kubernetes: uncordon GPU node
  kubectl uncordon "$GPU_NODE" || true
  # Observability: restore scrape interval
  kubectl -n infra annotate cm prometheus-config mode=ongrid --overwrite || true

else
  echo "Unknown mode: $MODE"
  exit 2
fi

echo "[✓] Done."
