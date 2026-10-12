cwt() {
  local target entry current
  local -a worktrees

  current=$(git rev-parse --show-toplevel 2>/dev/null) || {
    printf '请在 Git 仓库内运行\n' >&2
    return 1
  }

  while IFS= read -r -d '' entry; do
    case "$entry" in
      'worktree '*)
        [[ "${entry#worktree }" == "$current" ]] && continue
        worktrees+=("${entry#worktree }")
        ;;
    esac
  done < <(git worktree list --porcelain -z)

  if (( ${#worktrees[@]} == 0 )); then
    printf '没有其他可切换的 worktree\n'
    return 0
  fi

  target=$(
    printf '%s\0' "${worktrees[@]}" |
      fzf --read0 --print0 --no-multi \
          --height 40% --reverse --border \
          --prompt='worktree > '
  ) || return

  target=${target%$'\0'}
  builtin cd -- "$target"
}
