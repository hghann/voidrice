#!/bin/bash

msgId="031726"
MON="DP1"    # Discover monitor name with: xrandr | grep " connected"
STEP=5          # Step Up/Down brightnes by: 5 = ".05", 10 = ".10", etc.

CurrBright=$( xrandr --verbose --current | grep ^"$MON" -A5 | tail -n1 )
CurrBright="${CurrBright##* }"  # Get brightness level with decimal place

Left=${CurrBright%%"."*}        # Extract left of decimal point
Right=${CurrBright#*"."}        # Extract right of decimal point

MathBright="0"
[[ "$Left" != 0 && "$STEP" -lt 10 ]] && STEP=10     # > 1.0, only .1 works
[[ "$Left" != 0 ]] && MathBright="$Left"00          # 1.0 becomes "100"
[[ "${#Right}" -eq 1 ]] && Right="$Right"0          # 0.5 becomes "50"
MathBright=$(( MathBright + Right ))

[[ "$1" == "up" || "$1" == "+" ]] && MathBright=$(( MathBright + STEP ))
[[ "$1" == "down" || "$1" == "-" ]] && MathBright=$(( MathBright - STEP ))
[[ "${MathBright:0:1}" == "-" ]] && MathBright=0    # Negative not allowed
[[ "$MathBright" -gt 100  ]] && MathBright=100      # Can't go over 9.99

if [[ "${#MathBright}" -eq 3 ]] ; then
    MathBright="$MathBright"000         # Pad with lots of zeros
    CurrBright="${MathBright:0:1}.${MathBright:1:2}"
else
    MathBright="$MathBright"000         # Pad with lots of zeros
    CurrBright=".${MathBright:0:2}"
fi

xrandr --output "$MON" --brightness "$CurrBright"   # Set new brightness


function send_notification() {
	get_brightness="$(xrandr --verbose --current | grep ^"$MON" -A5 | tail -n1 | awk '{print $2}')"
	brightness_percent="$(echo ${get_brightness} 100\*p | dc)"
	print_brightness_percent="$(printf "%.0f\n" ${brightness_percent})"
	dunstify -a "Ext. disp. brightness" -u low -i /usr/share/icons/elementary/devices/48/computer-laptop.svg -r "$msgId" \
		-h int:value:"$print_brightness_percent" "Brightness ${print_brightness_percent}%" -t 2000
}

case $1 in
	up)
		ext_disp_brightness.sh +
		send_notification $1
		;;
	down)
		ext_disp_brightness.sh -
		send_notification $1
		;;
esac
