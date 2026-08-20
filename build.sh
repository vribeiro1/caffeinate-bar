#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

APP=build/CaffeineBar.app

echo "Cleaning ${APP}"
rm -rf "${APP}"
mkdir -p "${APP}/Contents/MacOS"

echo "Compiling Sources/main.swift"
swiftc -O -target arm64-apple-macos13.0 -o "${APP}/Contents/MacOS/CaffeineBar" Sources/main.swift

echo "Copying Info.plist"
cp Info.plist "${APP}/Contents/Info.plist"

echo "Ad-hoc signing bundle"
codesign -s - --force --deep "${APP}"

echo "Built ${APP}"

if [[ "${1:-}" == "install" ]]; then
    echo "Stopping any running CaffeineBar"
    pkill -f CaffeineBar || true
    echo "Removing previous /Applications/CaffeineBar.app"
    rm -rf /Applications/CaffeineBar.app
    echo "Installing to /Applications"
    cp -R "${APP}" /Applications/
    echo "Installed. Run: open /Applications/CaffeineBar.app"
fi
