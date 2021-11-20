#!/bin/bash

set -e

dotfiles_path="$(realpath --relative-to $HOME "$(dirname "$0")")"
self_name="$(basename "$0")"

### Args parsing
# from: https://medium.com/@Drew_Stokes/bash-argument-parsing-54f3b81a6a8f

dry_run=0
PARAMS=""
while (( "$#" )); do
  case "$1" in
    --dry-run)
      dry_run=1
      shift 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# set positional arguments in their proper place
eval set -- "$PARAMS"

### Helpers

log_info() {
  echo -e "$1: \033[32m$2\033[0m"
}

log_trace() {
  echo -e "\033[2m$@\033[0m"
}

run() {
  if [ $dry_run -eq 0 ]; then
    $@
  else
    log_trace $@
  fi
}

### Main

cd $HOME

git -C $dotfiles_path ls-files --cached --others --exclude-standard --full-name | \
  grep -Fv \
    -e $self_name \
    -e .gitignore \
    -e README.md \
  | while read target
do
  source="$dotfiles_path/$target"
  target_dir="$(dirname "$target")"

  # Create target dir if needed
  [ ! -d "$target_dir" ] && run mkdir -p "$target_dir"

  # Backup iff target file is not a symlink
  if [ -f "$target" ] && [ ! -L "$target" ]; then
    log_info "backup" "$target"
    run cp "$target" "$target~"
  fi

  # create symlink
  log_info "symlink" "$target"
  run ln -sf $source $target
done
