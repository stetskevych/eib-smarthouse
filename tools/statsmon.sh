#!/bin/bash
#
# statsmon.sh -- stats helper for the visualisation.
#
# Author: V'yacheslav Stetskevych

exec >/var/log/statsmon.log 2>&1

if [ "$(id -u)" != "0" ]; then
	echo "Must be root." >&2
	exit 1
fi

if ! command -v acpitool >/dev/null 2>&1; then
	echo "No acpitool in PATH." >&2
	exit 1
fi

battery_status() {
#acpitool | grep -m1 Battery | awk '{print $5}' | cut -d"." -f1
set $(acpitool | head -1)
value="${5%.*}"
# if less then 20 and charging, echo 21 to prevent low battery beeps
if on_ac_power && [ "$value" -le 20 ]; then
	echo 21
else
	echo "$value"
fi

}

wlan_status() {
line=$(iwconfig wlan0 | grep "Link Quality" | cut -d" " -f12 | cut -d= -f2)
# in case there is no wifi connection we will filter junk output here
if [ -z "$line" -o "$(grep / <<< "$line")" = "" ]; then
	echo 0
	break
fi
OIFS="$IFS"
IFS="/"
read q qmax <<< "$line" || { echo "Read line failed." >&2; exit 1; }
IFS="$OIFS"
if [ "$qmax" = 100 ]; then
	echo "$q"
else
	# if qmax != 100 we will make it so
	newq=$(bc <<< "scale=2; ($q/$qmax)*100")
	q=${newq%.*}
	echo "$q"
fi
}


#main()
outfile="/usr/local/eib/modules/system.tmp"
touch "$outfile"
chown eib:eib "$outfile"
chmod 755 "$outfile"

tempfile=$(tempfile) || { echo "Could not create temp file." >&2; exit 1; }
trap 'rm -f $tempfile; exit 1' TERM INT

while sleep 5; do

echo "<xml>" > $tempfile
echo "<param id=\"battery\" value=\"$(battery_status)\" />" >> $tempfile
echo "<param id=\"wifi\" value=\"$(wlan_status)\" />" >> $tempfile
echo "</xml>" >> $tempfile

cp "$tempfile" "$outfile"

done
