#!/usr/bin/env bash
# start-browser-session — Launch a Chrome + Xfce desktop accessible via noVNC.
# Usage: start-browser-session
# Then open http://localhost:${NOVNC_PORT} in your browser.
set -euo pipefail

DISPLAY_NUMBER="${DISPLAY_NUMBER:-99}"
export DISPLAY=":${DISPLAY_NUMBER}"
NOVNC_PORT="${NOVNC_PORT:-6080}"
VNC_PORT="${VNC_PORT:-5900}"
SCREEN_SIZE="${SCREEN_SIZE:-1440x900x24}"
BROWSER_BIN="${BROWSER_BIN:-google-chrome}"

mkdir -p "${HOME}/.vnc" "${HOME}/.cache/chromium-session"

# Track PIDs so cleanup is explicit (no pkill needed)
declare -a PIDS=()

cleanup() {
  for pid in "${PIDS[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
}
trap cleanup EXIT INT TERM

if pgrep -f "Xvfb ${DISPLAY}" >/dev/null 2>&1; then
  echo "A browser session is already running on ${DISPLAY}."
  exit 1
fi

echo "Starting Xvfb..."
Xvfb "${DISPLAY}" -screen 0 "${SCREEN_SIZE}" -ac +extension RANDR >/tmp/xvfb.log 2>&1 &
PIDS+=($!)
sleep 1

echo "Starting Xfce4 desktop..."
startxfce4 >/tmp/xfce4.log 2>&1 &
PIDS+=($!)
sleep 2

echo "Starting VNC server..."
x11vnc -display "${DISPLAY}" -forever -shared -nopw -rfbport "${VNC_PORT}" >/tmp/x11vnc.log 2>&1 &
PIDS+=($!)

echo "Starting noVNC proxy..."
websockify --web=/usr/share/novnc/ "${NOVNC_PORT}" "localhost:${VNC_PORT}" >/tmp/novnc.log 2>&1 &
PIDS+=($!)

if command -v "${BROWSER_BIN}" >/dev/null 2>&1; then
  echo "Launching ${BROWSER_BIN}..."
  "${BROWSER_BIN}" \
    --no-first-run \
    --no-default-browser-check \
    --no-sandbox \
    --disable-gpu \
    --disable-dev-shm-usage \
    --user-data-dir="${HOME}/.cache/chromium-session" \
    >/tmp/browser.log 2>&1 &
  PIDS+=($!)
else
  echo "Browser binary '${BROWSER_BIN}' not found."
  exit 1
fi

echo ""
echo "============================================"
echo "  Browser session is ready!"
echo "  Open: http://localhost:${NOVNC_PORT}"
echo "============================================"
echo ""

wait
