# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="y2kitty"

if [ -f ~/.config/kitty/hellokitty.ascii ]; then
    echo ""
    print -P "%F{#FF69B4}"
    cat ~/.config/kitty/hellokitty.ascii
    print -P "%f"
    echo ""
fi
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)
# eza aliases to override standard ls
alias ls="eza --icons --group-directories-first"
alias ll="eza -lh --icons --group-directories-first"
alias la="eza -lha --icons --group-directories-first"

# Initialize zoxide and bind it to the 'cd' command
eval "$(zoxide init zsh --cmd cd)"

source $ZSH/oh-my-zsh.sh
# Git operation abstractions
alias lg="lazygit"

# Editor routing (redirecting legacy Vim calls to Neovim)
alias vim="nvim"
