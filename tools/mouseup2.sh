#!/bin/bash
# mouseup2.sh
# Test for user activity and suspend the system if none detected.
# Author: V'acheslav Stetskevych, 2009.

# suspend interval in MINUTES
batt_interval="10" # on battery
ac_interval="240" # on ac
interrupt="5:" # look in /proc/interrupts for your value

poll_interval="10" # seconds between checks
logfile="/var/log/mouseup.log"

# if these values are reached, the system will suspend.
ac_sleepcount=$((ac_interval * 60 / poll_interval))
batt_sleepcount=$((batt_interval * 60 / poll_interval))
# these are the current _variable_ values.
ac_clicks=0
batt_clicks=0

log() {
echo "$(/bin/date "+%F %T"): $1" >> $logfile
}

get_current_clicks() {
cat /proc/interrupts | grep "$interrupt" | awk '{print $2}'
}

log "Starting mouseup. Suspend time on AC: ${ac_interval}M, on batt: ${batt_interval}M."
lastclicks=$(get_current_clicks)

# main
while sleep "$poll_interval"; do

currentclicks=$(get_current_clicks)
if [ "$currentclicks" -eq "$lastclicks" ]; then # the machine is idle
	if on_ac_power; then # we are on ac power
		((ac_clicks+=1))
		batt_clicks=0
	else # we are on battery
		((batt_clicks+=1))
		ac_clicks=0
	fi
else # there was some mouse activity
	ac_clicks=0
	batt_clicks=0
fi

#log "Lastclicks:$lastclicks Currentclicks:$currentclicks Ac_clicks:$ac_clicks Ac_sleepcount:$ac_sleepcount Batt_clicks:$batt_clicks Batt_sleepcount:$batt_sleepcount"

lastclicks=$currentclicks # save for the next poll iteration

if [ "$ac_clicks" -eq "$ac_sleepcount" ]; then
	ac_clicks=0
	log "AC sleep state reached."
	pm-suspend
elif [ "$batt_clicks" -eq "$batt_sleepcount" ]; then
	batt_clicks=0
	log "Battery sleep state reached."
	pm-suspend
fi

done

# end of script
