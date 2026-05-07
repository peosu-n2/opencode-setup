# Minimal Opencode aliases - remove what you don't use
# You already have 'to' command for navigation (~/.bin/.evaluate)

# Docker shortcuts (if useful)
alias dc='docker-compose'
alias dclogs='docker-compose logs -f'
alias dcrestart='docker-compose restart'

# Database connections (update with your actual databases)
# alias pgjna='psql postgresql://localhost/jna'
# alias pgsuperset='psql postgresql://localhost/superset'

# Opencode wrappers live in ~/.bin as standalone scripts (oc, ocr, ocrg).
# All three route through ~/.config/opencode/oc-sandbox.sh.
# Editing this file does nothing unless you source it from your shell init.

echo "Minimal opencode aliases loaded. You have 'to' for navigation."