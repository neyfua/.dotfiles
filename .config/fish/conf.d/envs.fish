# Environment variables
set -Ux TERMINAL foot
set -Ux EDITOR nvim

# Paths
set -gx PATH \
		/usr/bin \
    /usr/sbin \
    /usr/local/bin \
		/usr/lib64/ \
    $HOME/.local/bin

# Rust / Cargo
set -gx PATH $HOME/.cargo/bin $PATH

# .NET
set -Ux DOTNET_ROOT $HOME/.dotnet
set -gx PATH $HOME/.dotnet $HOME/.dotnet/tools $PATH

# npm
set -gx NPM_HOME "$HOME/.local/share/npm"
if not string match -q -- $NPM_HOME $PATH
  set -gx PATH "$NPM_HOME" $PATH
end

# pnpm
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end

# Spicetify
set -gx SPICETIFY "$HOME/.spicetify"
if not string match -q -- $SPICETIFY $PATH
	set -gx PATH "$SPICETIFY" $PATH
end

# Etc
# set -e LS_COLORS
set -e EZA_COLORS
