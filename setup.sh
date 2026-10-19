#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$(readlink -f "$0")")"

if [[ "$EUID" -eq 0 ]]; then
  echo "Run as your regular desktop user, not root." >&2
  exit 1
fi

sudo -v
sudo apt-get update
sudo apt-get install -y ansible git curl python3
ansible-playbook -i 'localhost,' playbooks/main.yml --ask-become-pass "$@"
