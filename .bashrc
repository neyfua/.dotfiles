#
# ~/.bashrc
#

## If not running interactively, don't do anything
[[ $- != *i* ]] && return
PS1='[\u@\h \W]\$ '

## Aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias nv='nvim'
alias py='python3'

#################### environment variables ####################

# Base paths
export PATH="/usr/local/bin:/usr/sbin:/usr/bin:$HOME/.local/bin:$PATH"

## Rust/Cargo
export PATH="$HOME/.cargo/bin:$PATH"

## Golang
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

## .NET
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"

## npm
export NPM_HOME="$HOME/.local/share/npm/bin"
[[ ":$PATH:" != *":$NPM_HOME:"* ]] && export PATH="$NPM_HOME:$PATH"

## pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
[[ ":$PATH:" != *":$PNPM_HOME:"* ]] && export PATH="$PNPM_HOME:$PATH"

## fcitx
export XMODIFIERS=@im=fcitx
export QT_IM_MODULE=fcitx
export QT_IM_MODULES="wayland;fcitx"
export GLFW_IM_MODULE=ibus

## Editor
export VISUAL=nvim
export EDITOR=${VISUAL}

## Misc
export COMP_WORDBREAKS="${COMP_WORDBREAKS//-}"

#################### miscellaneous ####################

## yazi
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

#################### prompt ####################

# Colors
cyan="\[\e[1;36m\]"
yellow="\[\e[1;33m\]"
red="\[\e[1;31m\]"
green="\[\e[1;32m\]"
blue="\[\e[1;34m\]"
normal="\[\e[0m\]"

# Get git branch name
_git_branch_name() {
    branch=$(git symbolic-ref --quiet HEAD 2>/dev/null)
    if [[ -n "$branch" ]]; then
        echo "${branch#refs/heads/}"
    else
        git rev-parse --short HEAD 2>/dev/null
    fi
}

# Is git dirty?
_is_git_dirty() {
    ! git diff-index --cached --quiet HEAD -- >/dev/null 2>&1 \
        || ! git diff --no-ext-diff --quiet --exit-code >/dev/null 2>&1
}

# Get hg branch
_hg_branch_name() {
    hg branch 2>/dev/null
}

# Is hg dirty?
_is_hg_dirty() {
    [[ -n "$(hg status -mard 2>/dev/null)" ]]
}

# Repo type (git/hg)
_repo_type() {
    if git rev-parse --git-dir >/dev/null 2>&1; then
        echo "git"
    elif hg root >/dev/null 2>&1; then
        echo "hg"
    else
        return 1
    fi
}

# Main Bash prompt
prompt_command() {
    local exit_status=$?

    # Arrow color
    local arrow_color="$green"
    [[ $exit_status -ne 0 ]] && arrow_color="$red"

    local arrow="${arrow_color}➜ "

    # Full working directory (not truncated)
    local cwd="${cyan}\w"

    # Repo info
    local repo_info=""
    local repo_type=$(_repo_type)

    if [[ -n "$repo_type" ]]; then
        local branch_name

        if [[ "$repo_type" == "git" ]]; then
            branch_name=$(_git_branch_name)
            local dirty=""
            _is_git_dirty && dirty="${yellow} ✗"
            repo_info=" ${blue}${repo_type}:(${red}${branch_name}${blue})${dirty}"
        elif [[ "$repo_type" == "hg" ]]; then
            branch_name=$(_hg_branch_name)
            local dirty=""
            _is_hg_dirty && dirty="${yellow} ✗"
            repo_info=" ${blue}${repo_type}:(${red}${branch_name}${blue})${dirty}"
        fi
    fi

    PS1="${arrow} ${cwd}${repo_info}${normal} "
}

PROMPT_COMMAND=prompt_command
. "$HOME/.aftman/env"
