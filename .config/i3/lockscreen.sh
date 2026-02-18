#!/bin/sh

fg_color=#e0def4
wrong_color=#eb6f92
highlight_color=#c4a7e7
verif_color=#9ccfd8
bg=#191724

pkill -SIGUSR1 dunst # pause

betterlockscreen -l blur -- --force-clock \
    --greeter-pos="46:1025" \
    --insidever-color=$bg --insidewrong-color=$bg --inside-color=$bg \
    --ringver-color=$verif_color --ringwrong-color=$wrong_color --ring-color=#26233a \
    --keyhl-color=$highlight_color --bshl-color=#f6c177 --separator-color=00000000 \
    --date-color=$fg_color --time-color=$fg_color \
    --time-str="%H:%M %p" \
    --greeter-text="$full_alias" --greeter-size=20 \
    --radius 25 --indicator \
    --lock-text="" --verif-text="" --greeter-text="Enter your password..." --no-modkey-text --wrong-text="" --noinput-text="" \
    --clock --date-font="GeistMono Nerd Font" --time-font="GeistMono Nerd Font"

pkill -SIGUSR2 dunst # resume
