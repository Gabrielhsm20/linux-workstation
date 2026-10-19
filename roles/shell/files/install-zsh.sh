#!/usr/bin/env bash
set -Eeuo pipefail
OMZ="$HOME/.oh-my-zsh"
if [[ ! -d "$OMZ" ]]; then
  git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$OMZ"
fi
CUSTOM="$OMZ/custom"
clone() { if [[ ! -d "$CUSTOM/$1" ]]; then git clone --depth 1 "$2" "$CUSTOM/$1"; fi; }
clone themes/spaceship-prompt https://github.com/spaceship-prompt/spaceship-prompt.git
ln -sfn "$CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$CUSTOM/themes/spaceship.zsh-theme"
clone plugins/zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git
clone plugins/zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git
clone plugins/zsh-completions https://github.com/zsh-users/zsh-completions.git
if [[ ! -e "$HOME/.zshrc" ]]; then
  cp "$OMZ/templates/zshrc.zsh-template" "$HOME/.zshrc"
fi
if ! grep -q 'BEGIN MANAGED MINT SETUP' "$HOME/.zshrc"; then
  cat >> "$HOME/.zshrc" <<'EOT'

# BEGIN MANAGED MINT SETUP
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="spaceship"
plugins=(git zsh-completions zsh-autosuggestions zsh-syntax-highlighting)
source "$ZSH/oh-my-zsh.sh"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
# END MANAGED MINT SETUP
EOT
fi
# Remove duplicate Oh My Zsh initialization from earlier configuration:
python3 - "$HOME/.zshrc" <<'PY'
from pathlib import Path
import re,sys
p=Path(sys.argv[1]); s=p.read_text(); mark='# BEGIN MANAGED MINT SETUP'; prefix,suffix=s.split(mark,1)
prefix=re.sub(r'^\s*(?:export ZSH=|ZSH_THEME=|plugins=|source \$ZSH/oh-my-zsh.sh).*\n','',prefix,flags=re.M)
p.write_text(prefix+mark+suffix)
PY
