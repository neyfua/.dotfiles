#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias nv='nvim'
alias py='python3'
alias c='gcc'
alias cpp='g++'
PS1='[\u@\h \W]\$ '

##############################################################################

# Envs
export PATH=/usr/bin:$PATH
export PATH=/usr/sbin:$PATH
export PATH=/usr/local/bin:$PATH
export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.cargo/bin:$PATH
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$DOTNET_ROOT:$PATH
export PATH="$HOME/.npm-global:$HOME/.npm-global/bin:$PATH"
export TERMINAL=foot
export VISUAL=nvim
export EDITOR={$VISUAL}

##############################################################################

# Misc

# yazi
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

unset LS_COLORS
unset EZA_COLORS

##############################################################################

# Prompt
if [ -f /usr/share/git/completion/git-prompt.sh ]; then
    source /usr/share/git/completion/git-prompt.sh
fi

# Colors
COLOR_CWD="\[\e[34m\]"          # blue
COLOR_GIT="\[\e[35m\]\[\e[1m\]" # bold magenta
COLOR_STATUS="\[\e[31m\]"
COLOR_RESET="\[\e[0m\]"

# Function to print last exit status
__prompt_status() {
    local status=$?
    if [ $status -ne 0 ]; then
        printf "${COLOR_STATUS}[%d]${COLOR_RESET} " "$status"
    fi
}

# Git status with counts (Fish-like)
parse_git_status() {
    git rev-parse --is-inside-work-tree &>/dev/null || return

    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)

    local modified untracked

    # Count ALL tracked changes (staged + unstaged)
    modified=$(git status --porcelain 2>/dev/null | grep -v '^??' | wc -l)

    # Count untracked
    untracked=$(git status --porcelain 2>/dev/null | grep '^??' | wc -l)

    local out="(${branch}"

    [ "$modified" -gt 0 ] && out+="|+${modified}"
    [ "$untracked" -gt 0 ] && out+="|?${untracked}"

    out+=")"

    printf "%s" "$out"
}

# Set prompt
PS1='$( __prompt_status )'"${COLOR_CWD}"'\w'"${COLOR_RESET}"' $(parse_git_status) \$ '
