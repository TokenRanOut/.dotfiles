if has_command screen; then
    export SCREENDIR="$HOME/.screen"
    mkdir -p -m 700 "$SCREENDIR"
fi
