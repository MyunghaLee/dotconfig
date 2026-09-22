# User configuration for ble.sh.

# Complete filesystem paths without regard to letter case.
bind 'set completion-ignore-case on'

# Use ble.sh-aware integrations instead of fzf's generic Readline bindings.
if command -v fzf >/dev/null 2>&1; then
  ble-import -d integration/fzf-completion
  ble-import -d integration/fzf-key-bindings
fi

if command -v zoxide >/dev/null 2>&1; then
  ble-import -d integration/zoxide
fi
