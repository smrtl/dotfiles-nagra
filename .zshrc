# # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.dotfiles/.zshrc.
# # Initialization code that may require console input (password prompts, [y/n]
# # confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

## Zinit
ZINIT_HOME="${HOME}/.local/share/zinit"
source "${ZINIT_HOME}/zinit.zsh"

# OMZ lib, no wait !
zinit for \
  OMZL::completion.zsh \
  OMZL::git.zsh \
  OMZL::history.zsh \
  OMZL::key-bindings.zsh \
  OMZL::prompt_info_functions.zsh \
  OMZL::theme-and-appearance.zsh \
  OMZT::robbyrussell

# Compinit & co, theme
# zinit for \
#   atinit"zicompinit; zicdreplay; setopt promptsubst" \
#     OMZT::robbyrussell

# Plugins
zinit wait lucid for \
  OMZP::git \
  OMZP::colored-man-pages \
  atinit"export NVM_LAZY_LOAD=true" lukechilds/zsh-nvm \
  davidparsson/zsh-pyenv-lazy

# # To customize prompt, run `p10k configure` or edit ~/.dotfiles/.p10k.zsh.
# [[ ! -f ~/.dotfiles/.p10k.zsh ]] || source ~/.dotfiles/.p10k.zsh
