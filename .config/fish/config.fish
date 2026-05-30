set fish_greeting

# theme
fish_config theme choose "Rosé Pine"

# foot
function mark_prompt_start --on-event fish_prompt
    echo -en "\e]133;A\e\\"
end


# Added by Antigravity CLI installer
set -gx PATH "/home/neyfua/.local/bin" $PATH
