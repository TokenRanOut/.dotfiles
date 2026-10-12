# opencode
add_path "$HOME/.opencode/bin"

if has_command opencode; then
    opencode() {
        local proxy_url="http://127.0.0.1:7890"
        local socks_url="socks5://127.0.0.1:7890"
        local bypass="localhost,127.0.0.1,registry.npmjs.org"

        HTTP_PROXY="$proxy_url" \
        HTTPS_PROXY="$proxy_url" \
        ALL_PROXY="$socks_url" \
        NO_PROXY="$bypass" \
        http_proxy="$proxy_url" \
        https_proxy="$proxy_url" \
        all_proxy="$socks_url" \
        no_proxy="$bypass" \
        command opencode "$@"
    }
fi
