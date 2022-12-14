#!/bin/bash
#  ____ _____ 
# |  _ \_   _|  Derek Taylor (DistroTube)
# | | | || |  	http://www.youtube.com/c/DistroTube
# | |_| || |  	http://www.gitlab.com/dwt1/ 
# |____/ |_|  	
# 
# Runs a random color script from my shell-color-scripts collection.
# Add "exec randomcolors.sh" to your bashrc or zshrc for more fun!
#
# Some minor edits to change the scripts directory to .local/bin

dirOptions=$(/bin/ls ~/.local/bin/shell-color-scripts | cut -d " " -f 1)
pickRandom=$(shuf -e ${dirOptions[@]} -n 1)
exec ~/.local/bin/shell-color-scripts/${pickRandom}
