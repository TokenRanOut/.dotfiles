mkdir -p "$HOME/.vim/.backup/"
mkdir -p "$HOME/.vim/.swp/"
mkdir -p "$HOME/.vim/.undo/"
if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
    curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
