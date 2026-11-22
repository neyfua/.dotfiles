set fish_greeting

# theme
fish_config theme choose "Rosé Pine"

# foot
function mark_prompt_start --on-event fish_prompt
    echo -en "\e]133;A\e\\"
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# paste on Ctrl+V in fish
bind \cv fish_clipboard_paste
bind -M insert \cv fish_clipboard_paste 2>/dev/null
