# Dotfiles for macOS

Super basic dotfiles management...

## Some requirements

- `brew install coreutils jq`

- [vim-plug](https://github.com/junegunn/vim-plug)
  ```
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  ```

## ZSH Configuration files

Loaded in order:

- `.zshenv`
  - always sourced (both interactive and non-interactive shells)
  - typically contains `$PATH`, `$EDITOR`, `$PAGER` or `$ZDOTDIR`
- `.zprofile`
  - login shell configuration
  - it's recommended to use either `.zprofile` or `.zlogin` but not both
- `.zshrc`
  - interactive shell configuration
- `.zlogin`
  - login shell configuration
  - it's recommended to use either `.zprofile` or `.zlogin` but not both
- `.zlogout`
  - read at logout within login shells

See also: https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2

## References

- https://github.com/zdharma-continuum/zinit
- https://github.com/ohmyzsh/ohmyzsh/
- https://zsh.sourceforge.io/Doc/Release/Expansion.html
