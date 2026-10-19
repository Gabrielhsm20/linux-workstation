#!/usr/bin/env bash
set -Eeuo pipefail
# Read-only inventory. The setup uses explicit values from group_vars/all.yml.
keys=(
  'org.cinnamon panels-enabled' 'org.cinnamon panels-height'
  'org.cinnamon panel-zone-icon-sizes' 'org.cinnamon panel-zone-symbolic-icon-sizes'
  'org.cinnamon.desktop.interface font-name' 'org.cinnamon.desktop.interface text-scaling-factor'
  'org.cinnamon.desktop.interface gtk-theme' 'org.cinnamon.desktop.interface icon-theme'
  'org.cinnamon.desktop.interface cursor-theme'
  'org.cinnamon.desktop.wm.preferences titlebar-font'
  'org.cinnamon.theme name'
  'org.cinnamon.desktop.peripherals.mouse speed'
  'org.cinnamon.desktop.peripherals.mouse natural-scroll'
)
for item in "${keys[@]}"; do
  read -r schema key <<< "$item"
  printf '%s %s: ' "$schema" "$key"
  gsettings get "$schema" "$key" 2>/dev/null || echo '(unavailable)'
done
