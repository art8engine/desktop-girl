#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP="Marin.app"
BIN="$APP/Contents/MacOS/Marin"

rm -rf "$APP" build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build

echo "compiling Swift sources..."
swiftc -O -framework AppKit -framework Cocoa \
  Sources/*.swift \
  -o "$BIN"

echo "assembling bundle..."
cp Resources/Info.plist "$APP/Contents/Info.plist"

if compgen -G "assets/sprites/*.png" > /dev/null; then
  cp assets/sprites/*.png "$APP/Contents/Resources/"
else
  echo "warning: assets/sprites/*.png not found — run 'make sprites' first" >&2
  exit 1
fi

echo "done -> $APP"
