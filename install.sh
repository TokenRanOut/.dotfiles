#!/bin/bash

set -o pipefail

GIT_URL="git@github.com:TokenRanOut/.dotfiles.git"
HTTP_URL="https://github.com/TokenRanOut/.dotfiles.git"

github_auth() {
    git ls-remote "$GIT_URL" >/dev/null 2>&1
}

exist() {
    if [[ ! -d ~/.dotfiles ]]; then
        return 1
    fi
    cd ~/.dotfiles || return 1
    local url
    url=$(git config --get remote.origin.url) || return 1
    if [[ $url != $GIT_URL && $url != $HTTP_URL ]]; then
        cd - >/dev/null
        return 1
    fi
    cd - >/dev/null
    return 0
}

update() {
    cd ~/.dotfiles || return 1
    if [[ -n $(git status --porcelain) ]]; then
        echo "Refusing to update: ~/.dotfiles has local changes"
        return 1
    fi
    git pull --ff-only || return 1
    cd - >/dev/null
}

init() {
    if github_auth; then
        git clone "$GIT_URL" ~/.dotfiles
    else
        git clone "$HTTP_URL" ~/.dotfiles
    fi
}

change_shell_to_zsh() {
    local zsh_path

    if [[ ! $SHELL =~ zsh ]]; then
        zsh_path=$(command -v zsh) || return 1
        sudo chsh -s "$zsh_path" "$USER"
    fi
}

if [[ ${1:-} == "dev" || ${1:-} == "server" ]]; then
    if exist; then
        update || exit 1
    else
        init || exit 1
    fi
    bash ~/.dotfiles/setup/.setup/setup.sh "$1" || exit 1
    change_shell_to_zsh || exit 1
else
    echo "Usage: $0 [dev|server]"
fi
