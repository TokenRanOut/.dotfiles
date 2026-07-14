#!/bin/bash

GIT_URL="git@github.com:TokenRanOut/.dotfiles.git"
HTTP_URL="https://github.com/TokenRanOut/.dotfiles.git"

github_auth() {
    ssh -T github.com
    local result=$?
    if [[ result -eq 255 ]]; then
        return 1
    fi
    return 0
}

exist() {
    if [[ ! -d ~/.dotfiles ]]; then
        return 1
    fi
    cd ~/.dotfiles
    local url=$(git config --get remote.origin.url)
    if [[ $url != $GIT_URL && $url != $HTTP_URL ]]; then
        return 1
    fi
    cd - >/dev/null
    return 0
}

update() {
    cd ~/.dotfiles
    git fetch origin && git reset --hard origin/master
    cd - >/dev/null
}

init() {
    if github_auth; then
        git clone $GIT_URL ~/.dotfiles
    else
        git clone $HTTP_URL ~/.dotfiles
    fi
}

change_shell_to_zsh() {
    if [[ ! $SHELL =~ zsh ]]; then
        sudo chsh -s /bin/zsh $USER
    fi
}

if exist; then
    update
else
    init
fi

if [[ $1 == "dev" || $1 == "server" ]]; then
    bash ~/.dotfiles/setup/.setup/setup.sh $1
    change_shell_to_zsh
else
    echo "Usage: $0 [dev|server]"
fi
