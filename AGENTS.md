# AGENTS.md

## Architecture: GNU Stow dotfiles

Each top-level directory is a **stow package** whose contents get symlinked into `$HOME`.
- The directory name is the package name; the internal path relative to that dir is the target location under `$HOME`.
  - e.g. `config/.config/opencode/AGENTS.md` → `~/.config/opencode/AGENTS.md`
  - e.g. `zsh/.zshrc` → `~/.zshrc`
- `stow` automatically ignores `.DS_Store` via `~/.stow-global-ignore`.
- Run `dotfile stow` (from `script/.script/bin/dotfile`) to re-stow after making changes.

## Install & setup

- **Entry point**: `install.sh` — clones or updates the repo into `~/.dotfiles`, then runs `setup/.setup/setup.sh`.
- **Profiles**: `dev` or `server`.
- **Package management**: `setup/.setup/setup.sh` defines packages in arrays (`BASE_PACKAGE_LIST`, `DEVELOP_PACKAGE_LIST`, `SERVER_PACKAGE_LIST`). Add new system packages there.
- **Extra installers** (`setup/.setup/installer/`) are run after package install. Add new ones to the `EXTRA_INSTALLER_LIST` array.
- **Canonical clone URL**: `git@github.com:PlayByMyself/.dotfiles.git` (SSH), fallback `https://github.com/PlayByMyself/.dotfiles.git` (HTTPS).

## Key files that agents may need to edit

- `setup/.setup/setup.sh` — package lists, extra installers
- `sheldon/.sheldon/plugins.toml` — zsh plugin manager config
- `zsh/.zshrc.d/*.zshrc` — shell config snippets (sourced by `zsh/.zshrc`)
- `git/.gitconfig` — global git config with `includeIf` conditional includes
- `vim/.vimrc`, `tmux/.tmux.conf`, `screen/.screenrc` — tool configs
- `script/.script/bin/` — custom utility scripts
- `config/.config/opencode/` — OpenCode AI config and skills

## Git quirks

- `git/.gitconfig` loads per-org configs via `includeIf "gitdir:…"`. Edit the conditional paths with care — matching is based on absolute filesystem paths.
- Git LFS is enabled for `*.jar` files (see `.gitattributes`).

## OpenCode config

OpenCode instructions are at `config/.config/opencode/AGENTS.md`. Skills live in `config/.config/opencode/skills/`. Both are stowed to `~/.config/opencode/` on the target machine.

## Website

The repo is published via GitHub Pages at `dotfiles.yejun.me` (`CNAME` file). The install one-liner in `README.md` uses this domain.

## What NOT to do

- Do not add files directly into `$HOME` — always create the correct stow-package directory structure.
- Do not commit company-specific skills (`**/skills/company` is gitignored).
- Do not run `install.sh` or `setup.sh` as root (enforced by `exit_if_root`).
