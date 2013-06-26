#!/bin/bash
# mouseup.sh
# Test mouse (or touchscreen) activity and suspend the system if none detected.
# Author: V'acheslav Stetskevych, 2009.

interval="10" # interval between checks
sleepcount="60"
interrupt="19:" # look in /proc/interrupts for your value
logfile="/var/log/mouseup.log"
count=0

log() {
echo "$(/bin/date "+%F %T"): $1" >> $logfile
}

get_current_clicks() {
cat /proc/interrupts | grep "$interrupt" | awk '{print $2}'
}

get_power_status() {
cat /proc/acpi/battery/BAT?/state | grep "charging state:" | awk '{print $3}'
}

log "Starting mouseup. Delay interval set to $(($interval * $sleepcount)) seconds."

lastclicks=$(get_current_clicks)

while true
do

sleep $interval

power=$(get_power_status)
if [ $power == "charged" -o $power == "charging" ]; then
	count=0
	continue
fi

clicks=$(get_current_clicks)
if [ $clicks -eq $lastclicks ]; then
	((count += 1))
else
	((count = 0))
fi

lastclicks=$clicks
#log "$lastclicks $clicks $count"

if [ $count -eq $sleepcount ]; then
	log "Clicks: $clicks. Going to sleep."
	/usr/sbin/pm-suspend
fi

done

#End of script
