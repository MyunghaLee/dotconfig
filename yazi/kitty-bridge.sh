#!/usr/bin/env bash
set -euo pipefail

mode=${1:-}
if [[ $mode != shell && $mode != command && $mode != prompt ]]; then
  printf 'Usage: %s shell|command|prompt [context...]\n' "$0" >&2
  exit 2
fi
shift

if [[ $mode == prompt ]]; then
  data=("$@")
  offset=0
  declare -A values=() counts=()

  take() {
    item=${data[offset]}
    offset=$((offset + 1))
  }

  read_file() {
    local key=$1 field
    for field in path url dir dir_url; do
      take
      values["$key:$field"]=$item
    done
  }

  read_tab() {
    local kind=$1 n count
    read_file "$kind:h:1"
    take
    count=$item
    counts["$kind:s"]=$count
    for ((n = 1; n <= count; n++)); do read_file "$kind:s:$n"; done
  }

  read_tab current
  read_tab next
  read_tab prev
  take
  yanked_count=$item
  counts[yanked]=$yanked_count
  for ((n = 1; n <= yanked_count; n++)); do read_file "yanked:y:$n"; done

  state_file=$(mktemp "${TMPDIR:-/tmp}/yazi-kitty-command.XXXXXXXX")
  declare -p values counts > "$state_file"
  export YAZI_KITTY_COMMAND_STATE=$state_file
  exec bash --rcfile "$(dirname -- "$0")/kitty-command.bash" -i
fi

if ! command -v kitten >/dev/null 2>&1; then
  printf 'kitten is required to open a Kitty window\n' >&2
  exit 127
fi

# Kitty uses the last OSC 7 path to clone a kitten ssh connection. Yazi's
# navigation does not update the parent shell's reported directory, so send
# the path of this Yazi-spawned process immediately before launching.
path=$PWD
encoded=''
LC_ALL=C
for ((i = 0; i < ${#path}; i++)); do
  char=${path:i:1}
  if [[ $char =~ [a-zA-Z0-9/._~-] ]]; then
    encoded+=$char
  else
    printf -v byte '%%%02X' "'$char"
    encoded+=$byte
  fi
done
printf '\033]7;file://%s%s\007' "$(hostname)" "$encoded" >/dev/tty

source=()
if [[ -n ${KITTY_WINDOW_ID:-} ]]; then
  source=(--source-window "id:$KITTY_WINDOW_ID")
fi

if [[ $mode == shell ]]; then
  kitten @ launch "${source[@]}" --type=os-window --os-window-class=kitty-yazi-shell --os-window-title='Yazi ! Shell' --cwd=last_reported
else
  kitten @ launch "${source[@]}" --type=os-window --os-window-class=kitty-yazi-command --os-window-title='Yazi : Command' --cwd=last_reported -- bash "$0" prompt "$@"
fi
