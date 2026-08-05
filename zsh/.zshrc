typeset -gaU path fpath

has_command() {
  (( $+commands[$1] ))
}

add_path() {
  local dir result=0

  for dir in "$@"; do
    if [[ -d "$dir" ]]; then
      path=("$dir" "${path[@]}")
    else
      result=1
    fi
  done

  return "$result"
}

add_fpath() {
  local dir result=0

  for dir in "$@"; do
    if [[ -d "$dir" ]]; then
      fpath=("$dir" "${fpath[@]}")
    else
      result=1
    fi
  done

  return "$result"
}

# source all .zshrc files in .zshrc.d directory
zsh_rc_dir="$HOME/.zshrc.d"
for rc_file in "$zsh_rc_dir"/*.zshrc(N); do
  source "$rc_file"
done
