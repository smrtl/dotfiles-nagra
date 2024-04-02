#!/bin/bash

set -e

SYMLINK_FOLDER_MARKER=".dotfiles-symlink-folder"

### Usage

die_usage() {
  [ -n "$1" ] && echo "Error: $@"
  echo "Usage: ${0##*/} [options]"
  echo "Options:"
  echo "  -d, --dry-run     Do not do anything, just log what would be done"
  echo "  -n, --no-backup   Do not backup pre-existing files"
  exit 1
}


### Parse args

args=()
dry_run=0
no_backup=0
while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--dry-run)
      dry_run=1
      shift
      ;;
    -n|--no-backup)
      no_backup=1
      shift
      ;;
    -*|--*)
      die_usage "unknown option: $1"
      ;;
    *)
      args+=("$1") # save positional arg
      shift
      ;;
  esac
done
set -- "${args[@]}" # restore positional args

if [[ -n "$1" ]]; then
  die_usage "invalid argument: $1"
fi


### Paths & Helpers

dotfiles_path="$(realpath "$(dirname "$0")")"
self_name="$(basename "$0")"

log_info() {
  echo -e "$1: \033[32m$2\033[0m"
}

log_trace() {
  echo -e "\033[2m$@\033[0m"
}

run() {
  if [ $dry_run -eq 0 ]; then "$@"; else log_trace $@; fi
}

symlink() {
  source="$dotfiles_path/$1"
  target=${1#home/}
  target_parent="$(dirname "$target")"

  # Create target parent if needed
  [ ! -d "$target_parent" ] && run mkdir -p "$target_parent"

  # Backup iff target file is not a symlink
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    if [ $no_backup -eq 0 ]; then
      log_info "backup" "$target"
      run mv "$target" "$target~"
    else
      run rm "$target"
    fi
  fi

  # Create symlink
  log_info "symlink" "$target"
  run ln -sf "$source" "$target"
}

### Main

cd $HOME

# List files and identify folders that should be symlinked
target_files=()
target_folders=()

while read -r target; do
  if [[ "${target##*/}" == "$SYMLINK_FOLDER_MARKER" ]]; then
    target_folders+=("${target%/*}")
  else
    target_files+=("$target")
  fi
done < <(git -C $dotfiles_path ls-files --cached --others --exclude-standard --full-name -- home)

# Symlink files if not in a symlinked folder
IFS=":"
target_folders_str="${IFS}${target_folders[@]}${IFS}"

for file in "${target_files[@]}"; do
  if ! [[ "$target_folders_str" =~ "${IFS}${file%/*}${IFS}" ]]; then
    symlink "$file"
  fi
done

# Symlink folders
for folder in "${target_folders[@]}"; do
  symlink "$folder"
done
