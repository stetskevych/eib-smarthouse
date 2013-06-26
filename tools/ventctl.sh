#!/bin/bash
# Ventilation control script.

case $1 in
  on)
    sendval="1"
    ;;
  off)
    sendval="0"
    ;;
  *)
    echo "Usage: $0 {on|off}"
    exit 1
    ;;
esac

if [ "$(groupcacheread ip:localhost 4/7/2 | cut -d" " -f4)" != 01 ]; then
	groupswrite ip:localhost 2/3/0 $sendval >/dev/null 2>&1 || exit 0
fi
