if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

if [ "$TERM" = "linux" ]; then
    setfont ter-u32n
fi
