if [[ -x "$HOME/.pyenv/bin/pyenv" && -z "${PYENV_SHELL:-}" ]]; then
    add_path "$HOME/.pyenv/bin"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi
