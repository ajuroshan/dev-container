#!/usr/bin/env bash
set -euo pipefail

DISPLAY_NUMBER="${DISPLAY_NUMBER:-99}"
export DISPLAY=":${DISPLAY_NUMBER}"
NOVNC_PORT="${NOVNC_PORT:-6080}"
VNC_PORT="${VNC_PORT:-5900}"
SCREEN_SIZE="${SCREEN_SIZE:-1440x900x24}"
BROWSER_BIN="${BROWSER_BIN:-google-chrome}"

mkdir -p "${HOME}/.vnc" "${HOME}/.cache/chromium-session"

cleanup() {
  pkill -f "websockify.*${NOVNC_PORT}" >/dev/null 2>&1 || true
  pkill -f "x11vnc.*${VNC_PORT}" >/dev/null 2>&1 || true
  pkill -f "Xvfb ${DISPLAY}" >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM

if pgrep -f "Xvfb ${DISPLAY}" >/dev/null 2>&1; then
  echo "A browser session is already running on ${DISPLAY}."
  exit 1
fi

Xvfb "${DISPLAY}" -screen 0 "${SCREEN_SIZE}" -ac +extension RANDR >/tmp/xvfb.log 2>&1 &
sleep 1

startxfce4 >/tmp/xfce4.log 2>&1 &
sleep 2

x11vnc -display "${DISPLAY}" -forever -shared -nopw -rfbport "${VNC_PORT}" >/tmp/x11vnc.log 2>&1 &
websockify --web=/usr/share/novnc/ "${NOVNC_PORT}" "localhost:${VNC_PORT}" >/tmp/novnc.log 2>&1 &

if command -v "${BROWSER_BIN}" >/dev/null 2>&1; then
  "${BROWSER_BIN}" \
    --no-first-run \
    --no-default-browser-check \
    --user-data-dir="${HOME}/.cache/chromium-session" \
    >/tmp/browser.log 2>&1 &
else
  echo "Browser binary '${BROWSER_BIN}' not found."
  exit 1
fi

echo "Browser session is available at http://localhost:${NOVNC_PORT}"
wait
