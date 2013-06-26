#!/bin/bash
# wait at boot and print dots
clear
wait="90"
echo -n "Waiting $wait seconds for the server to come up:"
i=0; while [ $i -lt $wait ]; do sleep 5; ((i += 5)); echo -n " ."; done
echo
# An alternate option:
# while ! echo test > /dev/tcp/servername/9999 >/dev/null 2>&1; do
#	echo -n " ."; done
