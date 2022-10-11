#!/bin/bash

msgId="430812"

function send_notification() {
	brightness="$(printf "%.0f\n" $(brillo -l -b))"
	dunstify -a "Change brightness" -u low -i /usr/share/icons/elementary/devices/48/computer-laptop.svg -r "$msgId" \
		-h int:value:"$brightness" "Brightness: ${brightness}%" -t 2000
}

case $1 in
	up)
		brillo -l -A 5 -q
		send_notification $1
		;;
	down)
		brillo -l -U 5 -q
		send_notification $1
		;;
esac
