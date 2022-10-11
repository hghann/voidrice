#!/bin/bash

msgId="472935"

function send_notification() {
	brightness="$(printf "%.0f\n" $(brillo -k -b))"
	dunstify -a "Change backlight" -u low -i /usr/share/icons/elementary/devices/48/input-keyboard.svg -r "$msgId" \
		-h int:value:"$brightness" "Keyboard: ${brightness}%" -t 2000
}

case $1 in
	up)
		brillo -k -A 5 -q
		send_notification $1
		;;
	down)
		brillo -k -U 5 -q
		send_notification $1
		;;
esac
