#!/bin/sh
# Usage:
#   session.sh insert <session_id>       new session at current number + 1, higher numbers shifted up
#   session.sh rename <session_id> <name> rename keeping the "<n> ~ " prefix so the order never changes
#   session.sh renumber                 close numeric gaps (0,3,4 -> 0,1,2)

num_of() { printf '%s' "$1" | sed -n 's/^\([0-9][0-9]*\).*/\1/p'; }
label_of() { printf '%s' "$1" | sed 's/^[0-9][0-9]* *~ *//'; }

case "$1" in
insert)
	sid=$2
	cur=$(tmux display-message -p -t "$sid" '#{session_name}')
	n=$(num_of "$cur")
	[ -n "$n" ] || n=$(printf '%s' "$sid" | tr -dc 0-9)
	new=$((n + 1))
	# shift highest first so renames never collide
	tmux list-sessions -F '#{session_name}' |
		awk -v new="$new" 'match($0, /^[0-9]+/) { i = substr($0, 1, RLENGTH) + 0; if (i >= new) print i "\t" $0 }' |
		sort -rn |
		while IFS="$(printf '\t')" read -r i name; do
			rest=$(label_of "$name")
			if [ "$rest" = "$name" ]; then
				tmux rename-session -t "=$i" "$((i + 1))"
			else
				tmux rename-session -t "$name" "$((i + 1)) ~ $rest"
			fi
		done
	tmux new-session -d -s "$new" && { tmux switch-client -t "$new" 2>/dev/null || :; }
	;;
rename)
	sid=$2
	name=$3
	[ -n "$name" ] || exit 0
	cur=$(tmux display-message -p -t "$sid" '#{session_name}')
	n=$(num_of "$cur")
	[ -n "$n" ] || n=$(printf '%s' "$sid" | tr -dc 0-9)
	tmux rename-session -t "$sid" "$n ~ $name"
	;;
renumber)
	# close the gaps: sort by current number, reassign 0..n keeping labels
	tmux list-sessions -F '#{session_name}' |
		awk 'match($0, /^[0-9]+/) { print substr($0, 1, RLENGTH) + 0 "\t" $0 }' |
		sort -n |
		awk -F'\t' '{ printf "%d\t%s\n", NR - 1, $2 }' |
		while IFS="$(printf '\t')" read -r i name; do
			[ "$(num_of "$name")" = "$i" ] && continue
			rest=$(label_of "$name")
			if [ "$rest" = "$name" ]; then
				tmux rename-session -t "=$name" "$i"
			else
				tmux rename-session -t "=$name" "$i ~ $rest"
			fi
		done
	;;
*)
	echo "usage: $0 insert <id> | rename <id> <name>" >&2
	exit 1
	;;
esac
