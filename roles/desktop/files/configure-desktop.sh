#!/usr/bin/env bash
set -Eeuo pipefail
# Run as the Cinnamon session user; never via sudo.
if [[ "${XDG_CURRENT_DESKTOP:-}" != *Cinnamon* && "${XDG_CURRENT_DESKTOP:-}" != *cinnamon* ]]; then
  echo 'Warning: no Cinnamon session detected; ensure the correct user session is active.' >&2
fi
if ! command -v gsettings >/dev/null || ! command -v dconf >/dev/null; then
  echo 'gsettings and dconf are required.' >&2; exit 1
fi
# Capture output first: `cmd | grep -q` under pipefail fails with SIGPIPE (141).
SCHEMAS="$(gsettings list-schemas)"
has_schema() { grep -Fxq "$1" <<<"$SCHEMAS"; }
has_key() { grep -Fxq "$2" <<<"$(gsettings list-keys "$1")"; }
set_key() {
  local schema="$1" key="$2" value="$3"
  if has_schema "$schema" && has_key "$schema" "$key"; then
    gsettings set "$schema" "$key" "$value"
  else
    echo "Unavailable key, skipping: $schema $key" >&2
  fi
}
# Ansible may hand lists/dicts over as Python reprs (single quotes); normalize to JSON.
json_value() {
  python3 -c 'import ast, json, sys
raw = sys.argv[1] or sys.argv[2]
try:
    val = json.loads(raw)
except ValueError:
    val = ast.literal_eval(raw)
print(json.dumps(val))' "$1" "$2"
}
set_key org.cinnamon panels-enabled "${CINNAMON_PANELS_ENABLED:-['1:0:bottom']}"
set_key org.cinnamon panels-height "${CINNAMON_PANELS_HEIGHT:-['1:36']}"
set_key org.cinnamon panel-zone-icon-sizes "'$(json_value "${CINNAMON_PANEL_ICON_SIZES-}" '[{"panelId": 1, "left": 24, "center": 0, "right": 24}]')'"
set_key org.cinnamon panel-zone-symbolic-icon-sizes "'$(json_value "${CINNAMON_PANEL_SYMBOLIC_ICON_SIZES-}" '[{"panelId": 1, "left": 26, "center": 28, "right": 16}]')'"
set_key org.cinnamon.desktop.interface font-name "${CINNAMON_FONT_NAME:-Ubuntu 10}"
set_key org.cinnamon.desktop.interface text-scaling-factor "${CINNAMON_FONT_SCALE:-1.0}"
set_key org.cinnamon.desktop.interface gtk-theme "${CINNAMON_GTK_THEME:-Mint-Y-Dark-Blue}"
set_key org.cinnamon.desktop.interface icon-theme "${CINNAMON_ICON_THEME:-Mint-Y-Blue}"
set_key org.cinnamon.desktop.interface cursor-theme "${CINNAMON_CURSOR_THEME:-Bibata-Modern-Classic}"
set_key org.cinnamon.desktop.wm.preferences titlebar-font "${CINNAMON_TITLEBAR_FONT:-Ubuntu Medium 10}"
set_key org.cinnamon.theme name "${CINNAMON_SHELL_THEME:-Mint-Y-Dark-Blue}"
set_key org.cinnamon.desktop.peripherals.mouse speed "${CINNAMON_MOUSE_SPEED:-0.0}"
set_key org.cinnamon.desktop.peripherals.mouse natural-scroll "${CINNAMON_MOUSE_NATURAL_SCROLL:-false}"
# Menu applet (Panel > Icon size): stored per applet instance in its spices JSON, not in gsettings.
for f in "$HOME"/.config/cinnamon/spices/menu@cinnamon.org/*.json; do
  [[ -f "$f" ]] || continue
  python3 - "$f" "${CINNAMON_MENU_ICON_SIZE:-24}" <<'PYSCRIPT'
import json, sys
path, size = sys.argv[1], float(sys.argv[2])
with open(path) as fh:
    data = json.load(fh)
if 'menu-icon-size' in data:
    data['menu-icon-size']['value'] = size
    with open(path, 'w') as fh:
        json.dump(data, fh, indent=4)
PYSCRIPT
done
# Enable applets on the right of panel 1 (skips ones already enabled or not installed).
if [[ -n "${CINNAMON_APPLETS:-}" ]] && has_schema org.cinnamon; then
  updated="$(python3 - "$(gsettings get org.cinnamon enabled-applets)" "$CINNAMON_APPLETS" "$HOME/.local/share/cinnamon/applets" <<'PYSCRIPT'
import ast, os, sys
enabled = ast.literal_eval(sys.argv[1].removeprefix('@as '))
for uuid in sys.argv[2].split():
    if not os.path.isdir(os.path.join(sys.argv[3], uuid)) or any(e.split(':')[3] == uuid for e in enabled):
        continue
    next_id = max([int(e.split(':')[4]) for e in enabled] + [-1]) + 1
    enabled.append(f'panel1:right:0:{uuid}:{next_id}')
print(repr(enabled))
PYSCRIPT
)"
  set_key org.cinnamon enabled-applets "$updated"
fi
# Free the Print key and bind it to Flameshot, preserving other custom shortcuts.
if has_schema org.cinnamon.desktop.keybindings.media-keys && has_schema org.cinnamon.desktop.keybindings; then
  set_key org.cinnamon.desktop.keybindings.media-keys screenshot '[]'
  current="$(gsettings get org.cinnamon.desktop.keybindings custom-list)"
  updated="$(python3 - "$current" <<'PYSCRIPT'
import ast, sys
values = ast.literal_eval(sys.argv[1].removeprefix('@as '))
if 'flameshot-print' not in values:
    values.append('flameshot-print')
print(repr(values))
PYSCRIPT
)"
  set_key org.cinnamon.desktop.keybindings custom-list "$updated"
  root=/org/cinnamon/desktop/keybindings/custom-keybindings/flameshot-print
  dconf write "$root/name" "'Flameshot'"
  dconf write "$root/command" "'flameshot gui'"
  dconf write "$root/binding" "['Print']"
fi
