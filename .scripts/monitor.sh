#!/bin/bash
case "$1" in
    left)
        xrandr --output DP1 --off
        ;;
    right)
        xrandr --output DP2 --off
        ;;
    all)
        xrandr --output DP1 --off --output DP2 --off
        ;;
    on)
        xrandr --output DP1 --auto --output DP2 --auto
        xrandr --output DP1 --rotate left --output DP2 --rotate normal
        xrandr --output DP1 --auto --right-of DP2
        ;;
esac
exit 0



