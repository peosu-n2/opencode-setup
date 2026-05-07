#!/bin/bash
# Run opencode in a bubblewrap sandbox.
#
# Visible read-write inside:
#   - $PWD
#   - ~/projects (your work tree root)
#   - ~/Desktop
#   - ~/.bin (for quick script edits)
#   - opencode config + data + cache + state dirs
#   - ~/.android (adbkey, AVDs, debug.keystore — adb auth + emulator state)
#   - ~/.gradle (build cache + daemon — avoids re-downloading on every build)
#   - ~/.m2 (Maven local repo, used by Gradle for mavenLocal())
# Visible read-only inside:
#   - /usr, /etc, /opt, ~/.libs, ~/.python-environments, ~/.pyenv
#   - ~/.ssh (for git push via SSH)
#   - ~/.gitconfig
#   - ~/.docker (config.json — registry auth for docker push)
#   - ~/Android/Sdk (adb, emulator, build-tools, platforms — RO so the agent can't run sdkmanager)
#   - ~/.java (Java prefs)
#   - opencode auth.json, host config.json (shadowed by config.sandbox.json)
# /dev passthroughs:
#   - /dev/kvm (only if present — for emulator hardware acceleration)
# Invisible:
#   - $HOME everything else (~/.aws, ~/.gnupg, ~/.netrc, browser profiles, etc.)
#   - other users, /root
#
# Network: shared (required for the DeepSeek API and any localhost services on host).
# /tmp:    tmpfs, isolated from host.
#
# config.sandbox.json is auto-regenerated from config.json on every run, so the
# sandbox config never drifts from the source of truth.
#
# Usage: oc-sandbox.sh run --agent ship "your prompt"
#        oc-sandbox.sh                                 # interactive TUI in $PWD
set -euo pipefail

OC_DIR=$HOME/.config/opencode
PWD_ABS=$(realpath "$PWD")

# Resolve the opencode binary at run-time so the same script works across machines
# (don't hardcode an install-specific path like $HOME/.libs/node22/bin/opencode).
OPENCODE_BIN=$(command -v opencode 2>/dev/null) || OPENCODE_BIN=""
[ -n "$OPENCODE_BIN" ] || {
  echo "oc-sandbox: 'opencode' not found in PATH. Install via: curl -fsSL https://opencode.ai/install | bash" >&2
  exit 1
}

# Refuse to run from paths that would collapse the sandbox isolation.
# A --bind "$PWD" "$PWD" issued AFTER --tmpfs "$HOME" would shadow the tmpfs
# and re-expose the host's real $HOME. Same risk for / and /home.
case "$PWD_ABS" in
  /|/home)
    echo "oc-sandbox: refusing to run from $PWD_ABS — would expose sensitive paths." >&2
    exit 1
    ;;
esac

# When PWD is exactly $HOME, skip the trailing $PWD bind (the explicit subdir
# binds for ~/projects, ~/Desktop, ~/.bin etc. already cover what the agent needs).
# Otherwise add it so $PWD is RW inside the sandbox.
if [ "$PWD_ABS" = "$HOME" ]; then
  PWD_BIND=()
else
  PWD_BIND=(--bind "$PWD_ABS" "$PWD_ABS")
fi

# Regenerate sandbox config (flip every "ask" → "allow") so it always matches the source config.
jq 'walk(if . == "ask" then "allow" else . end)' "$OC_DIR/config.json" > "$OC_DIR/config.sandbox.json"

# Best-effort: resolve the gh CLI token on the host (where the OS keyring + dbus
# are reachable) and forward it as GH_TOKEN. This lets `gh` inside the sandbox
# authenticate even on hosts that store the token in the keyring instead of
# hosts.yml — without exposing dbus to the agent. If gh is missing or not
# logged in, skip silently; the agent will just get an unauthenticated gh.
GH_TOKEN_ENV=()
if command -v gh >/dev/null 2>&1; then
  if GH_TOKEN_VAL=$(gh auth token 2>/dev/null) && [ -n "$GH_TOKEN_VAL" ]; then
    GH_TOKEN_ENV=(--setenv GH_TOKEN "$GH_TOKEN_VAL")
  fi
fi

exec bwrap \
  --ro-bind /usr /usr \
  --symlink usr/bin /bin \
  --symlink usr/bin /sbin \
  --symlink usr/lib /lib \
  --symlink usr/lib /lib64 \
  --ro-bind /etc /etc \
  --tmpfs /etc/ssh/ssh_config.d \
  --ro-bind-try /opt /opt \
  --tmpfs "$HOME" \
  --ro-bind "$HOME/.libs" "$HOME/.libs" \
  --bind "$HOME/.bin" "$HOME/.bin" \
  --bind-try "$HOME/.opencode" "$HOME/.opencode" \
  --ro-bind "$HOME/.python-environments" "$HOME/.python-environments" \
  --ro-bind "$HOME/.pyenv" "$HOME/.pyenv" \
  --bind "$HOME/.config/opencode" "$HOME/.config/opencode" \
  --ro-bind "$HOME/.config/opencode/config.sandbox.json" "$HOME/.config/opencode/config.json" \
  --bind "$HOME/.local/share/opencode" "$HOME/.local/share/opencode" \
  --ro-bind "$HOME/.local/share/opencode/auth.json" "$HOME/.local/share/opencode/auth.json" \
  --bind-try "$HOME/.cache/opencode" "$HOME/.cache/opencode" \
  --bind-try "$HOME/.local/state/opencode" "$HOME/.local/state/opencode" \
  --bind-try "$HOME/projects" "$HOME/projects" \
  --bind-try "$HOME/Desktop" "$HOME/Desktop" \
  --ro-bind-try "$HOME/.ssh" "$HOME/.ssh" \
  --ro-bind-try "$HOME/.gitconfig" "$HOME/.gitconfig" \
  --ro-bind-try "$HOME/.docker" "$HOME/.docker" \
  --ro-bind-try "$HOME/.config/gh" "$HOME/.config/gh" \
  --ro-bind-try "$HOME/Android/Sdk" "$HOME/Android/Sdk" \
  --bind-try "$HOME/.android" "$HOME/.android" \
  --bind-try "$HOME/.gradle" "$HOME/.gradle" \
  --bind-try "$HOME/.m2" "$HOME/.m2" \
  --ro-bind-try "$HOME/.java" "$HOME/.java" \
  --bind-try "$HOME/.local/npm" "$HOME/.local/npm" \
  --tmpfs /tmp \
  ${PWD_BIND[@]+"${PWD_BIND[@]}"} \
  ${GH_TOKEN_ENV[@]+"${GH_TOKEN_ENV[@]}"} \
  --proc /proc \
  --dev /dev \
  --dev-bind-try /dev/kvm /dev/kvm \
  --share-net \
  --die-with-parent \
  --setenv HOME "$HOME" \
  --setenv USER "$USER" \
  --setenv PATH "$HOME/.bin:$HOME/.libs/node22/bin:$HOME/.local/npm/bin:$HOME/.pyenv/shims:$HOME/Android/Sdk/platform-tools:$HOME/Android/Sdk/emulator:/usr/local/bin:/usr/bin:/bin" \
  --setenv DOCKER_HOST "tcp://127.0.0.1:2375" \
  --setenv DOCKER_BUILDKIT "0" \
  --setenv OC_HOST_PROXY "http://127.0.0.1:7878" \
  --setenv ANDROID_HOME $HOME/Android/Sdk \
  --setenv ANDROID_SDK_ROOT $HOME/Android/Sdk \
  --setenv JAVA_HOME /usr/lib/jvm/default \
  --chdir "$PWD_ABS" \
  "$OPENCODE_BIN" "$@"
