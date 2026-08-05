export NVM_DIR="$HOME/.nvm"

# Expose the default Node version without sourcing nvm.sh. This makes Node and
# globally installed npm commands visible to completion and syntax highlighting.
_nvm_add_default_bin() {
  [[ -r "$NVM_DIR/alias/default" ]] || return

  local version alias_file version_dir installed_version name prefix
  local -a installed_versions
  local depth

  read -r version < "$NVM_DIR/alias/default"

  # Resolve aliases such as: lts/* -> lts/krypton -> v24.16.0.
  for depth in {1..10}; do
    alias_file="$NVM_DIR/alias/$version"
    [[ -r "$alias_file" ]] || break
    read -r version < "$alias_file"
  done

  installed_versions=("$NVM_DIR"/versions/node/*(N/n))

  if [[ "$version" == node || "$version" == stable ]]; then
    version_dir=${installed_versions[-1]}
  else
    prefix=${version#v}
    for installed_version in "${installed_versions[@]}"; do
      name=${installed_version:t}
      if [[ "$name" == "v$prefix" || "$name" == "v$prefix".* ]]; then
        version_dir=$installed_version
      fi
    done
  fi

  [[ -n "$version_dir" && -d "$version_dir/bin" ]] && add_path "$version_dir/bin"
}
_nvm_add_default_bin
unset -f _nvm_add_default_bin

# Only the nvm shell function itself needs nvm.sh.
nvm() {
  unset -f nvm
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  nvm "$@"
}
