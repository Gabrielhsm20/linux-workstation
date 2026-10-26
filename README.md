# Linux Workstation Setup

Automated local workstation provisioning with Ansible.

## Layout

```text
linux-setup/
├── setup.sh                      # Installs Ansible and runs the playbook
├── playbooks/main.yml            # Local playbook and role orchestration
├── group_vars/all.yml            # Versions, extensions, web apps, desktop preferences
└── roles/
    ├── base/tasks/main.yml
    ├── applications/tasks/main.yml
    ├── applications/files/install-postman.sh
    ├── docker/tasks/main.yml
    ├── github_cli/tasks/main.yml      # Official GitHub CLI (gh) APT repository
    ├── editor/tasks/main.yml
    ├── claude_code/tasks/main.yml     # Official native Claude Code installation
    ├── codex_cli/tasks/main.yml       # Official standalone Codex CLI installation
    ├── chatgpt_community/             # Optional community desktop app (never runs by default)
    ├── node/tasks/main.yml
    ├── node/files/install-node.sh
    ├── shell/tasks/main.yml
    ├── shell/files/install-zsh.sh
    ├── webapps/tasks/main.yml
    ├── webapps/templates/webapp.desktop.j2
    └── desktop/
        ├── tasks/main.yml
        └── files/
            ├── configure-desktop.sh
            └── backup-desktop.sh
```

## Run

```bash
./setup.sh
```

### Select a component

```bash
./setup.sh --tags desktop
./setup.sh --tags docker
./setup.sh --tags github
./setup.sh --tags dev
./setup.sh --tags shell
./setup.sh --tags claude
./setup.sh --tags codex
```

### View current Cinnamon values

```bash
./roles/desktop/files/backup-desktop.sh
```

All desktop values are explicit in `group_vars/all.yml`. The setup does **not** copy monitor configuration or bulk-import `dconf`.

## Base packages and responsibilities

- `base` installs general prerequisites: `git` (repositories), `curl` and `wget` (HTTP downloads), `ca-certificates` and `gnupg` (TLS / repository signatures), `unzip` and `xz-utils` (archives), and `build-essential` (compiler/make tooling needed by source builds).
- `shell` installs `zsh` and `fonts-powerline` (prompt glyphs).
- `desktop` installs `flameshot` and `dconf-cli` (Cinnamon shortcut preferences).
- `python3-psutil` was removed: none of the current tasks uses it.

## Web app icons

`web_apps` entries in `group_vars/all.yml` support `icon` and `icon_url`:

- `icon_url`: downloads an SVG to `~/.local/share/icons/hicolor/scalable/apps/<slug>.svg` and uses it in the `.desktop` launcher.
- `icon`: use a local icon file path or an installed icon theme name when `icon_url` is empty.
- If both are empty, the launcher falls back to the Chrome icon until you supply one.

WhatsApp uses an SVG from Simple Icons (community-maintained brand icon). The WhatsApp Business icon is intentionally left blank for you to configure. Both apps launch `web.whatsapp.com` with separate browser profiles. Neither automatically creates or logs into a Business account.

Run `./setup.sh --tags webapps` to refresh the launchers and icons.

## Caveats

- Review the repository and the scripts before executing. Third-party install downloads are not checksum-pinned.
- Execute from your signed-in Cinnamon desktop session, as a regular user.
- Docker group membership grants root-equivalent access; log out and back in after installation.
- A session restart may be needed for Cinnamon preferences and the default Zsh shell.
- WhatsApp and WhatsApp Business launch the same web address in separate Chrome profiles; login is manual.
- The optional ChatGPT Community role builds third-party source and downloads the current signed stable upstream payload. Review the community repository before running it; source and build requirements can change.
- This is a starter project and has not been exercised end-to-end on a clean Mint install. Test before wiping your current machine.

## Claude Code

The `claude_code` role installs Claude Code using Anthropic's official **native installer**, not the deprecated global npm package. It does not require Node.js or `sudo`, and is skipped if `~/.local/bin/claude` already exists. Native installations update automatically.

Run `./setup.sh --tags claude` to install only Claude Code. Open a new terminal, run `claude --version`, and then `claude` to sign in. If the shell cannot find Claude, add `~/.local/bin` to your `PATH`. Authentication is interactive and is not automated.

## Codex CLI and VS Code

`codex_cli` uses the official standalone installer (`https://chatgpt.com/codex/install.sh`) and does not require npm or NVM. `OpenAI.chatgpt` is already listed in `vscode_extensions` as the official Codex VS Code extension, so there is no duplicate installation.

Run `./setup.sh --tags codex` and then `codex --version`, `codex`. Sign in interactively. The installer will be skipped if `~/.local/bin/codex` exists.

## ChatGPT Community (optional)

Skipped by default. Install or update explicitly:

```bash
./setup.sh --tags chatgpt_community         # Install only if missing
./setup.sh --tags chatgpt_community_update  # Pull sources and rebuild
```

Automatic updates are disabled. Updates replace the existing package.

```bash
dpkg-query -W codex-desktop     # Verify installation
command -v codex-desktop       # Locate executable
sudo apt remove codex-desktop  # Uninstall
```
