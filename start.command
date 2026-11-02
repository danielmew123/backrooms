#!/bin/bash
# Starts the Backrooms cam: local web server + a clean 1280x720 Chrome window titled "Backrooms".
cd "$(dirname "$0")"
PORT=47123
if ! lsof -iTCP:$PORT -sTCP:LISTEN >/dev/null 2>&1; then
  python3 -m http.server $PORT --bind 127.0.0.1 >/dev/null 2>&1 &
  sleep 0.6
fi
open -na "Google Chrome" --args --app="http://127.0.0.1:$PORT/?${1:-}" --window-size=1280,752 --window-position=60,60 \
  --user-data-dir="$PWD/.chrome-profile" --no-first-run --no-default-browser-check
echo "Backrooms running at http://127.0.0.1:$PORT  (close this window any time; server keeps running)"
