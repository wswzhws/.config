# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="/Users/amoswang/.oh-my-zsh"
export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST

ZSH_THEME="powerlevel10k/powerlevel10k"
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Set plugins here
source /Users/amoswang/.oh-my-zsh/plugins 
plugins=(git
    zsh-autosuggestions
    zsh-syntax-highlighting
    extract
    web-search) 
source $ZSH/oh-my-zsh.sh
source <(fzf --zsh)

source ~/.config/cmake-script/cmake.zsh

# User configuration
# export MANPATH="/usr/local/man:$MANPATH"
alias espidf=". ~/esp/esp-idf/export.sh"
alias vi="nvim"
alias lg="lazygit"

alias lsl="ls -lrth"
alias cdc="cd ~/Documents/CodeBox"

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

export IDF_PATH="/Users/amoswang/esp/esp-idf"
export LUA_ROOT="/opt/homebrew/Cellar/lua/5.4.7"
export VCPKG_ROOT="/Users/amoswang/development/vcpkg"
export PATH="$PATH:$VCPKG_ROOT"


export HOMEBREW_NO_AUTO_UPDATE=true
export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles/bottles

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

