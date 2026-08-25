if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

if [ "$TERM" = "linux" ]; then
    setfont ter-u32n
fi
. "$HOME/.aftman/env"
