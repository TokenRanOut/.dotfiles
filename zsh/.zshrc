add_path() {
  local result=0;
  for NEW_PATH in $@; do
    if [[ -d "$NEW_PATH" ]] && [[ ":$PATH:" != *":$NEW_PATH:"* ]]; then
      export PATH="$NEW_PATH:$PATH"
    else
      result=1
    fi
  done
  return result
}

add_fpath() {
  local result=0;
  for NEW_FPATH in $@; do
    if [[ -d "$NEW_FPATH" ]] && [[ ":$FPATH:" != *":$NEW_FPATH:"* ]]; then
      export FPATH="$NEW_FPATH:$FPATH"
    else
      result=1
    fi
  done
  return result
}



# source all .zshrc files in .zshrc.d directory
setopt null_glob
ZSH_RC_DIR="$HOME/.zshrc.d"
if [[ -d $ZSH_RC_DIR ]]; then
  for RC_FILE in $ZSH_RC_DIR/*.zshrc; do
    source $RC_FILE
  done
fi
unsetopt null_glob


