eval "$(sheldon --config-dir ~/.sheldon --data-dir ~/.sheldon source)"

_fzf_complete_git() {
  local lbuf=$1 revision path_query
  local -a command_words
  command_words=(${(z)lbuf})

  if [[ $command_words[2] == show && $prefix == *:* ]]; then
    revision=${prefix%%:*}
    path_query=${prefix#*:}
    local prefix=$path_query
    _fzf_complete -- "$lbuf$revision:" < <(
      command git ls-tree -r --name-only "$revision" 2>/dev/null
    )
    return
  fi

  _fzf_path_completion "$prefix" "$lbuf"
}
