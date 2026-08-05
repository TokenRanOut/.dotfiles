#!/bin/bash

set -o pipefail

vim_dir="$HOME/.vim"
mkdir -p "$vim_dir/.backup" "$vim_dir/.swp" "$vim_dir/.undo" || exit 1

if [[ ! -f "$vim_dir/autoload/plug.vim" ]]; then
    curl --proto '=https' --tlsv1.2 -fLo "$vim_dir/autoload/plug.vim" \
        --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
