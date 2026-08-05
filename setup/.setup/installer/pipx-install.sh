#!/bin/bash

set -o pipefail

BASE_PYTHON_PACKAGE_LIST=(
    tldr
)

DEVELOP_PYTHON_PACKAGE_LIST=(
    poetry
)

SERVER_PYTHON_PACKAGE_LIST=()

if [[ $1 = "dev" ]]; then
    packages=("${BASE_PYTHON_PACKAGE_LIST[@]}" "${DEVELOP_PYTHON_PACKAGE_LIST[@]}")
elif [[ $1 = "server" ]]; then
    packages=("${BASE_PYTHON_PACKAGE_LIST[@]}" "${SERVER_PYTHON_PACKAGE_LIST[@]}")
else
    echo "Usage: $0 [dev|server]"
    exit 1
fi

for package in "${packages[@]}"; do
    pipx install --force "$package" || exit 1
done
