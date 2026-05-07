#!/bin/bash
# install.sh — set up opencode sandbox + tool suite from this repo
# Idempotent. Run on a fresh machine after `git clone`. Symlinks files into
# place so future `git pull` updates flow through without re-running install.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
echo "→ installing from $REPO"
echo "→ user=$USER home=$HOME"

# Safely create a symlink; back up any existing real file/dir
link_safe() {
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    # already a symlink — quietly replace
    ln -sfn "$src" "$dst"
  elif [ -e "$dst" ]; then
    # real file/dir — back up first
    local bak="${dst}.bak.$(date +%Y%m%d-%H%M%S)"
    mv "$dst" "$bak"
    ln -s "$src" "$dst"
    echo "  ↳ backed up existing $(basename "$dst") to $(basename "$bak")"
  else
    # absent
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
  fi
}


# === 1. System deps ===
if command -v pacman >/dev/null; then
  echo "→ Arch detected; installing deps via pacman"
  sudo pacman -S --needed --noconfirm \
    bubblewrap jq fd ripgrep bat dasel xh skopeo \
    github-cli docker docker-buildx \
    grim slurp wl-clipboard imagemagick \
    nodejs npm
elif command -v apt-get >/dev/null; then
  echo "→ Debian/Ubuntu detected; installing deps via apt"
  sudo apt-get update
  sudo apt-get install -y \
    bubblewrap jq fd-find ripgrep bat dasel skopeo \
    gh docker.io docker-buildx \
    grim slurp wl-clipboard imagemagick \
    nodejs npm
  command -v fd >/dev/null || sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
else
  echo "✗ unsupported distro; install manually: bubblewrap jq fd ripgrep bat dasel xh skopeo gh docker imagemagick grim slurp wl-clipboard nodejs npm"
  exit 1
fi

# === 2. opencode binary ===
if ! command -v opencode >/dev/null && [ ! -x "$HOME/.opencode/bin/opencode" ]; then
  echo "→ installing opencode (not found on PATH)"
  curl -fsSL https://opencode.ai/install | bash
else
  echo "→ opencode already present at $(command -v opencode || echo "$HOME/.opencode/bin/opencode")"
fi

# === 3. ~/.bin (symlink each oc-* script) ===
mkdir -p "$HOME/.bin"
for f in "$REPO"/bin/*; do
  link_safe "$f" "$HOME/.bin/$(basename "$f")"
done
echo "→ symlinked ~/.bin/oc-* (count: $(ls -1 "$REPO"/bin/ | wc -l))"

# === 4. ~/.config/opencode (symlink config files individually) ===
mkdir -p "$HOME/.config/opencode"
for f in config.json oc-sandbox.sh AGENTS.md aliases.sh package.json package-lock.json; do
  link_safe "$REPO/config/opencode/$f" "$HOME/.config/opencode/$f"
done
link_safe "$REPO/config/opencode/plugins" "$HOME/.config/opencode/plugins"

# Install plugin npm deps
if [ -f "$HOME/.config/opencode/package.json" ]; then
  (cd "$HOME/.config/opencode" && npm install --silent --prefer-offline 2>&1 | tail -3)
fi

# === 5. systemd user services ===
mkdir -p "$HOME/.config/systemd/user"
for f in "$REPO"/systemd/user/*.service; do
  link_safe "$f" "$HOME/.config/systemd/user/$(basename "$f")"
done
systemctl --user daemon-reload
for f in "$REPO"/systemd/user/*.service; do
  base=$(basename "$f" .service)
  systemctl --user enable --now "$base.service" 2>&1 | tail -1 || echo "  ! $base failed (may need manual config — see service file)"
done

# === 6. oc-docker-proxy container ===
if command -v docker >/dev/null; then
  if ! docker ps --filter name=oc-docker-proxy --format '{{.Names}}' | grep -q oc-docker-proxy; then
    echo "→ starting oc-docker-proxy container"
    "$HOME/.bin/oc-docker-proxy-up" || echo "  ! docker-proxy start failed (run: sudo systemctl start docker; then ~/.bin/oc-docker-proxy-up)"
  else
    echo "→ oc-docker-proxy already running"
  fi
fi

# === 7. Secret population checklist ===
cat <<EOF

╔══════════════════════════════════════════════════════════════════╗
║  Install complete. Now populate secrets:                         ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  1. opencode auth (DeepSeek/OpenRouter API keys):                ║
║       opencode auth login                                        ║
║                                                                  ║
║  2. GitHub CLI (forwarded to sandbox as GH_TOKEN):               ║
║       gh auth login                                              ║
║                                                                  ║
║  3. Docker registry (for ghcr.io push from inside sandbox):      ║
║       echo \$(gh auth token) | docker login ghcr.io \\           ║
║         -u \$(gh api user --jq .login) --password-stdin          ║
║                                                                  ║
║  4. Test the sandbox:                                            ║
║       cd /tmp && oc run --agent build "say hi"                   ║
║                                                                  ║
║  See README.md for details on each step.                         ║
╚══════════════════════════════════════════════════════════════════╝
EOF
