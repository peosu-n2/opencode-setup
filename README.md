# opencode-setup

Reproducible setup for the opencode sandbox + tool suite. Symlinks configs and
scripts from this repo into `~/.bin/`, `~/.config/opencode/`, and
`~/.config/systemd/user/` so `git pull` updates them in place.

## Quick start (new machine)

```bash
git clone https://github.com/peosu-n2/opencode-setup ~/projects/opencode-setup
cd ~/projects/opencode-setup
./install.sh
```

Then populate secrets (the install script prints these too):

1. **API keys (DeepSeek, OpenRouter):**
   ```bash
   opencode auth login
   ```
2. **GitHub CLI:**
   ```bash
   gh auth login
   ```
3. **Docker registry (for `docker push ghcr.io/...` from inside sandbox):**
   ```bash
   echo $(gh auth token) | docker login ghcr.io \
     -u $(gh api user --jq .login) --password-stdin
   ```

## What this installs

- `~/.bin/oc-*` scripts (sandbox launcher, vision helpers, screenshot, etc.)
- `~/.config/opencode/` config (config.json, oc-sandbox.sh, AGENTS.md, plugins)
- `~/.config/systemd/user/oc-*.service` (host-proxy, playwright-mcp)
- `oc-docker-proxy` container (read-mostly Docker access for the sandbox)

## Architecture

- **`oc-sandbox.sh`** — bwrap-based sandbox launcher. Mounts a tmpfs over
  `$HOME`, then RW-binds only the directories the agent needs (~/.bin,
  ~/projects, ~/Desktop, opencode dirs) and RO-binds read-only paths (~/.ssh,
  ~/.gitconfig, ~/.docker, ~/.config/gh).
- **`oc-host-proxy`** — small HTTP service on `:7878` exposing clipboard and
  screenshot to the sandboxed agent (without giving it Wayland access).
- **`oc-docker-proxy`** — Tecnativa docker-socket-proxy on `127.0.0.1:2375`,
  filtered to allow build/push/inspect but deny run/exec/login.

## Updating

```bash
cd ~/projects/opencode-setup
git pull
# config edits flow through immediately (symlinks)
# if oc-sandbox.sh changed, restart any running TUI
# if install.sh changed, re-run it
```

## Files NOT in this repo (populate locally)

- `~/.local/share/opencode/auth.json` — API keys (use `opencode auth login`)
- `~/.docker/config.json` — registry creds (use `docker login ghcr.io ...`)
- `~/.config/gh/hosts.yml` — GitHub CLI auth (use `gh auth login`)
- `~/.ssh/` — SSH keys for git push

See `secrets.example/` for templates.

## Editing config

`config.json`, `oc-sandbox.sh`, etc. are symlinks into the repo. Edit them
in place; commit + push from `~/projects/opencode-setup` to share with other
machines.

`config.sandbox.json` is auto-regenerated from `config.json` by every
`oc-sandbox.sh` launch — do not edit it directly, do not commit it.
