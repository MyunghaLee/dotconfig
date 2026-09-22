# Bash rcfile for the one-command Kitty window opened from Yazi.
# Use the usual interactive setup so Flyline, completion, aliases, and prompt load.
if [[ -r $HOME/.bashrc ]]; then source "$HOME/.bashrc"; fi

if [[ -z ${YAZI_KITTY_COMMAND_STATE:-} || ! -r $YAZI_KITTY_COMMAND_STATE ]]; then
  printf 'Yazi command context is missing\n' >&2
  exit 1
fi
source "$YAZI_KITTY_COMMAND_STATE"
command rm -- "$YAZI_KITTY_COMMAND_STATE"
unset YAZI_KITTY_COMMAND_STATE

_yazi_expand_command() {
  local line=$1 i=0 j char kind code number lower group limit start stop n field value quoted
  expanded=''
  while ((i < ${#line})); do
    char=${line:i:1}
    if [[ $char != '%' ]]; then
      expanded+=$char
      i=$((i + 1))
      continue
    fi
    if [[ ${line:i+1:1} == '%' ]]; then
      expanded+='%'
      i=$((i + 2))
      continue
    fi

    kind=current
    j=$((i + 1))
    case ${line:j:1} in
      t) kind=next; j=$((j + 1));;
      T) kind=prev; j=$((j + 1));;
    esac
    code=${line:j:1}
    case $code in
      h|H|s|S|d|D|y|Y) ;;
      *) expanded+='%'; i=$((i + 1)); continue;;
    esac
    j=$((j + 1))
    number=''
    while [[ ${line:j:1} =~ [0-9] ]]; do
      number+=${line:j:1}
      j=$((j + 1))
    done

    lower=${code,,}
    if [[ $lower == y ]]; then
      kind=yanked
      group=y
      limit=${counts[yanked]}
    elif [[ $lower == h ]]; then
      group=h
      limit=1
    else
      group=s
      limit=${counts["$kind:s"]}
    fi

    if [[ -n $number ]]; then
      start=$((10#$number))
      stop=$start
    else
      start=1
      stop=$limit
    fi
    for ((n = start; n <= stop && n <= limit; n++)); do
      if [[ $lower == d ]]; then
        [[ $code == D ]] && field=dir_url || field=dir
      else
        [[ $code =~ [A-Z] ]] && field=url || field=path
      fi
      value=${values["$kind:$group:$n:$field"]:-}
      if [[ -n $value ]]; then
        printf -v quoted '%q' "$value"
        if ((n > start)); then expanded+=' '; fi
        expanded+=$quoted
      fi
    done
    i=$j
  done
}

_yazi_prepare_line() {
  [[ $READLINE_LINE =~ [^[:space:]] ]] || return 0
  _yazi_expand_command "$READLINE_LINE"
  READLINE_LINE=$expanded
  READLINE_POINT=${#READLINE_LINE}
  _yazi_command_pending=1
}

_yazi_exit_after_command() {
  if [[ ${_yazi_command_pending:-} ]]; then exit; fi
}
PROMPT_COMMAND+=(_yazi_exit_after_command)

if [[ $(type -t flyline) == builtin ]]; then
  for key in Enter Ctrl+j; do
    flyline key bind "$key" 'always=runBashCommand(_yazi_prepare_line)+submitOrNewline'
    flyline key bind "$key" 'tabCompletionEntrySelected=tabCompletionAcceptEntry'
  done
  unset key
else
  bind -x '"\C-x\C-z":_yazi_prepare_line'
  bind '"\C-j": accept-line'
  bind '"\C-m": "\C-x\C-z\C-j"'
fi
