# Dotfiles for macOS

Super basic dotfiles management...

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

## References

- https://github.com/zdharma-continuum/zinit
- https://github.com/ohmyzsh/ohmyzsh/
- https://zsh.sourceforge.io/Doc/Release/Expansion.html
