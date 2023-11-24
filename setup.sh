#!/bin/bash

set -e


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


### Main

cd $HOME

git -C $dotfiles_path ls-files --cached --others --exclude-standard --full-name -- home \
  | while read target
do
  source_file="$dotfiles_path/$target"
  target_file=${target#home/}
  target_dir="$(dirname "$target_file")"

  # Create target dir if needed
  [ ! -d "$target_dir" ] && run mkdir -p "$target_dir"

  # Backup iff target file is not a symlink
  if [ -f "$target_file" ] && [ ! -L "$target_file" ]; then
    if [ $no_backup -eq 0 ]; then
      log_info "backup" "$target_file"
      run mv "$target_file" "$target_file~"
    else
      run rm "$target_file"
    fi
  fi

  # Create symlink
  log_info "symlink" "$target_file"
  run ln -sf "$source_file" "$target_file"
done
