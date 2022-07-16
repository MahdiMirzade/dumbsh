#!/usr/bin/env bash
#
# dumbsh: Dumb Shell
#
# You'll need to set your keyboard layout to "us,*" in order to generate a layout table.
# Example:
#         setxkbmap -layout us,ir
#

# Default variables
DUMBSH_KEY_INDEX="${DUMBSH_KEY_INDEX:-${XDG_DATA_HOME:-$HOME/.local/share}/dumbsh_table}"
DUMBSH_ASK_REPLACE="${DUMBSH_ASK_REPLACE:-TRUE}"

# Generete layout table
generateTable() {
	KEYDEFS=$(cat /usr/local/include/X11/keysymdef.h)
	getUnicode() {
		echo "$KEYDEFS" | grep " XK_$1 " | grep -o "U+[0-9a-zA-Z]*" | sed 's/+//'
	}
	xmodmap -pke | awk '$4 != $6 {print $4" "$5" "$6" "$7}' | while read -r A B C D; do
		if [ $(printf "$A" | wc -m) -ge 2 ]; then
			A="\\$(getUnicode "$A")"
		fi
		if [ $(printf "$B" | wc -m) -ge 2 ]; then
			B="\\$(getUnicode "$B")"
		fi
		if [ $(printf "$C" | wc -m) -ge 2 ]; then
			C="\\$(getUnicode "$C")"
		fi
		if [ $(printf "$D" | wc -m) -ge 2 ]; then
			D="\\$(getUnicode "$D")"
		fi
		[ -z "$C" ] || printf "$C=$A\n"
		[ -z "$D" ] || printf "$D=$B\n"
		unset A B C D
	done
}

[ -f "$DUMBSH_KEY_INDEX" ] || generateTable > "$DUMBSH_KEY_INDEX"

# Translate 2nd layout to English
translate() {
	INPUT=$1
	OUTPUT=$INPUT
	for (( i=0; i<${#INPUT}; i++ )); do
		CHAR=${INPUT:$i:1}
		NEWCHAR=$(grep -- "${CHAR}=" "$DUMBSH_KEY_INDEX" | cut -d '=' -f 2)
		OUTPUT=${OUTPUT//${CHAR}/${NEWCHAR:-$CHAR}}
		unset CHAR NEWCHAR
	done
	printf "$OUTPUT"
}

# Handle command not found
command_not_found_handler() {
	INPUT=$*
	OUTPUT=$(translate "$INPUT")

	if [ -z "$(diff <(printf "%s" "$INPUT") <(printf "%s" "$OUTPUT"))" ]; then
		printf "\033[31mbash: %s: command not found\033[0m\n" "$INPUT"
	else
		case "$DUMBSH_ASK_REPLACE" in
			[Tt][Rr][Uu][Ee]|1)
				printf "\033[34mDid you mean %s? [y/N]\033[0m " "$OUTPUT"
				read ANS
				case "$ANS" in
					[Yy][Ee][Ss]|Y|y)
						printf "\033[32mRunning:\033[0m %s...\n" "$OUTPUT"
						eval $OUTPUT
					;;
					*)
						return 1;
					;;
				esac
			;;
			*)
				printf "\033[33m%s -> %s\033[0m\n" "$INPUT" "$OUTPUT"
				printf "\033[32mRunning:\033[0m %s...\n" "$OUTPUT"
				eval $OUTPUT
			;;
		esac
	fi

	unset INPUT OUTPUT
}

# Handle command not found - bash version
command_not_found_handle() { command_not_found_handler "$*"; }
