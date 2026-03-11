#!/usr/bin/env bash
set -euo pipefail

# Auto-restart wrapper for the Fynd solver.
# Restarts on transient crashes (e.g. Tycho "Missing block!" stream errors).
# Usage: ./fynd-run.sh [--fynd-dir DIR] [--rpc-url URL] [--protocols LIST]
# Required env vars: RPC_URL (or --rpc-url), TYCHO_API_KEY

FYND_DIR="${FYND_DIR:-$HOME/fynd}"
RPC_URL="${RPC_URL:-}"
PROTOCOLS="${PROTOCOLS:-uniswap_v2,uniswap_v3}"
TYCHO_URL="${TYCHO_URL:-tycho-beta.propellerheads.xyz}"
MAX_RESTARTS=10
RESTART_WINDOW=300  # seconds — reset counter if stable this long
RESTART_DELAY=5

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fynd-dir) FYND_DIR="$2"; shift 2 ;;
    --rpc-url) RPC_URL="$2"; shift 2 ;;
    --protocols) PROTOCOLS="$2"; shift 2 ;;
    --tycho-url) TYCHO_URL="$2"; shift 2 ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

if [[ -z "$RPC_URL" ]]; then
  echo "ERROR: RPC_URL not set. Export it or pass --rpc-url."
  exit 1
fi

if [[ -z "${TYCHO_API_KEY:-}" ]]; then
  echo "ERROR: TYCHO_API_KEY not set."
  exit 1
fi

if [[ ! -f "$FYND_DIR/Cargo.toml" ]]; then
  echo "ERROR: $FYND_DIR does not contain Cargo.toml. Check --fynd-dir."
  exit 1
fi

restart_count=0
burst_start=0

while true; do
  now=$(date +%s)

  # Reset counter if solver ran stably for RESTART_WINDOW since burst began
  if [[ $burst_start -gt 0 ]] && [[ $((now - burst_start)) -gt $RESTART_WINDOW ]]; then
    restart_count=0
    burst_start=0
  fi

  if [[ $restart_count -ge $MAX_RESTARTS ]]; then
    echo "[fynd-run] Hit $MAX_RESTARTS restarts within ${RESTART_WINDOW}s. Giving up."
    exit 1
  fi

  # Track when the burst of crashes started
  if [[ $restart_count -eq 0 ]]; then
    burst_start=$now
  fi

  echo "[fynd-run] Starting solver (attempt $((restart_count + 1))) at $(date)"

  exit_code=0
  cd "$FYND_DIR"
  TYCHO_API_KEY="$TYCHO_API_KEY" RUST_LOG=info \
    cargo run --release -- serve \
      --tycho-url "$TYCHO_URL" \
      --rpc-url "$RPC_URL" \
      --protocols "$PROTOCOLS" \
    || exit_code=$?

  restart_count=$((restart_count + 1))
  echo "[fynd-run] Solver exited (code $exit_code) at $(date). Restarting in ${RESTART_DELAY}s..."
  sleep "$RESTART_DELAY"
done
