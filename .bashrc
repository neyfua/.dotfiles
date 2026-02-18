#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# alias ls='ls --color=auto'
alias ls='eza --icons always'
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
# zoxide
eval "$(zoxide init --cmd cd bash)"

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

# Prompt like my fishy shell
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
