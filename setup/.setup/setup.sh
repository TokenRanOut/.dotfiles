#!/bin/bash

# Define package lists
readonly BASE_PACKAGE_LIST=(
    zsh
    stow
    git
    python3
    wget
    curl
    screen
    vim
    tmux
    gpg
    pipx
    fzf
)

readonly DEVELOP_PACKAGE_LIST=()

readonly SERVER_PACKAGE_LIST=(
    fail2ban
)

readonly EXTRA_INSTALLER_LIST=(
    cargo-install.sh
    pipx-install.sh
)

# Define package manager settings
init_package_manager() {
    case "$OSTYPE" in
        freebsd*)
            MANAGER_COMMAND="sudo pkg"
            MANAGER_INSTALL="install -y"
            MANAGER_UPDATE="update"
            MANAGER_PACKAGE_LIST=(
                sudo
            )
            ;;
        linux-gnu*)
            if type -p apt-get >/dev/null; then
                MANAGER_COMMAND="sudo apt-get"
                MANAGER_INSTALL="install -y"
                MANAGER_UPDATE="update"
                MANAGER_PACKAGE_LIST=(
                    build-essential
                    libssl-dev
                    sudo
                )
            elif type -p yum >/dev/null; then
                MANAGER_COMMAND="sudo yum"
                MANAGER_INSTALL="install -y"
                MANAGER_UPDATE="makecache"
                MANAGER_PACKAGE_LIST=(
                    gcc
                    openssl-devel
                    sudo
                )
            elif type -p pacman >/dev/null; then
                MANAGER_COMMAND="sudo pacman"
                MANAGER_INSTALL="-S --noconfirm --needed"
                MANAGER_UPDATE="-Sy"
                MANAGER_PACKAGE_LIST=(
                    base-devel
                    sudo
                )
            else
                echo "Unsupported package manager"
                exit 1
            fi
            ;;
        darwin*)
            if type -p brew >/dev/null; then
                MANAGER_COMMAND="brew"
                MANAGER_INSTALL="install"
                MANAGER_UPDATE="update"
                MANAGER_PACKAGE_LIST=()
            else
                echo "Unsupported package manager"
                exit 1
            fi
            ;;
        *)
            echo "Unsupported OS"
            exit 1
            ;;
    esac
}

# Define functions for installing packages, initializing sheldon, stowing dotfiles, and checking if running as root
install_packages() {
    local profile="$1"
    local all_package_list=("${BASE_PACKAGE_LIST[@]}")
    case "$profile" in
        "dev")
            all_package_list+=("${DEVELOP_PACKAGE_LIST[@]}")
            ;;
        "server")
            all_package_list+=("${SERVER_PACKAGE_LIST[@]}")
            ;;
        *)
            echo "Usage: $0 [dev|server]"
            exit 1
            ;;
    esac
    all_package_list+=("${MANAGER_PACKAGE_LIST[@]}")

    $MANAGER_COMMAND $MANAGER_UPDATE
    echo "All package list: ${all_package_list[*]}"
    $MANAGER_COMMAND $MANAGER_INSTALL "${all_package_list[@]}"
}

init_sheldon() {
    if [[ ! -d ~/.sheldon ]]; then
        mkdir ~/.sheldon
    fi
}

stow_dotfiles() {
    cd ~/.dotfiles && ls -d1 */ | xargs stow -S
    cd - >/dev/null
}

exit_if_root() {
    if [[ $EUID -eq 0 ]]; then
        echo "This script should not be run as root"
        exit 1
    fi
}

# Run functions
exit_if_root
init_package_manager
init_sheldon
PROFILE="$1"
install_packages "$PROFILE"
for installer in "${EXTRA_INSTALLER_LIST[@]}"; do
    bash "$(dirname "$0")/installer/$installer" "$PROFILE"
done
stow_dotfiles
