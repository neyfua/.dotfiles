set fish_greeting

# theme
fish_config theme choose "Rosé Pine"

# zoxide
zoxide init --cmd cd fish | source

# foot
function mark_prompt_start --on-event fish_prompt
    echo -en "\e]133;A\e\\"
end
