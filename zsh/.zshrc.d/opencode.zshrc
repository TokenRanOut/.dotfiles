# opencode
add_path "$HOME/.opencode/bin"

if has_command opencode; then
    alias opencode="HTTP_PROXY=http://127.0.0.1:7890 HTTPS_PROXY=http://127.0.0.1:7890 NO_PROXY=localhost,127.0.0.1 opencode"
fi
