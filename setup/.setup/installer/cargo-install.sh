#!/bin/bash

set -o pipefail

export PATH="$HOME/.cargo/bin:$PATH"

BASE_RUST_PACKAGE_LIST=(
    sheldon
    fnm
)

DEVELOP_RUST_PACKAGE_LIST=(
    cargo-edit
)

SERVER_RUST_PACKAGE_LIST=()

rustup_init() {
    if command -v rustup >/dev/null 2>&1; then
        rustup update stable
    else
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
}

if [[ $1 == "dev" ]]; then
    rustup_init || exit 1
    cargo install --locked "${BASE_RUST_PACKAGE_LIST[@]}" "${DEVELOP_RUST_PACKAGE_LIST[@]}"
elif [[ $1 == "server" ]]; then
    rustup_init || exit 1
    cargo install --locked "${BASE_RUST_PACKAGE_LIST[@]}" "${SERVER_RUST_PACKAGE_LIST[@]}"
else
    echo "Usage: $0 [dev|server]"
    exit 1
fi
