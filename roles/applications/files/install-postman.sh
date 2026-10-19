#!/usr/bin/env bash
set -Eeuo pipefail
mkdir -p "$HOME/.local/opt" "$HOME/.local/share/applications"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
curl -fL --retry 3 https://dl.pstmn.io/download/latest/linux64 -o "$TMP/postman.tar.gz"
tar -xzf "$TMP/postman.tar.gz" -C "$TMP"
mv "$TMP/Postman" "$HOME/.local/opt/Postman"
cat > "$HOME/.local/share/applications/postman.desktop" <<ENTRY
[Desktop Entry]
Name=Postman
Exec=$HOME/.local/opt/Postman/Postman
Icon=$HOME/.local/opt/Postman/app/resources/app/assets/icon.png
Type=Application
Categories=Development;
Terminal=false
ENTRY
