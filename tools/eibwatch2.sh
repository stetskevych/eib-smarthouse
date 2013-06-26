#!/bin/bash
#
# Watch the state of the system and relauch stuff as needed
# Author: Vyacheslav Stetskevych

# ChangeLog:
# === 20100715 ===
# * If no modem connected, make NO attempt to restart stuff.
# * Launch openvpn with '--writepid' and check the pidfile, because pgrep fails.

# Are we using internet here?
inetwatch=1
# Are we watching the eib services?
eibwatch=1
services=(eibd server.php reader.php)
# Are we syncing time?
timesync=1
# Do we want logging?
logging=1 # if 0, the script is silent
logfile="/var/log/eibwatch.log"
# Openvpn pidfile location
vpnpid="/var/run/openvpn.pid"

# Service variables
fail=0
failseq=0
modemresetseq=1
scriptname="$(basename $0)"
# Redirect all the script output in case we get errors
exec 1>>/var/log/eibwatch.out 2>&1


log() {
if [ "$logging" = 1 ]; then
	echo "$(/bin/date "+%F %T"): $1" >> $logfile
fi
}

timesync() {
php /usr/local/eib/timesync.php
}

ping_probe() {
for ((i=0; i<5; i++)); do
	if ping -c1 www.google.com >/dev/null; then
		return 0 # ping successful!
	else
		# the connection might be flapping at the moment,
		# so we wait and try again
		sleep 10
	fi
done
return 1 # all pings failed
}

modem_exists() {
ln -sf /dev/ttyACM? /dev/modem
if ! [ -e $(readlink /dev/modem) ]; then
	log "modem_exists(): No modem connected. Doing nothing."
	return 1
fi
}

inet_check() {
if ! modem_exists; then return 1; fi

if ! kill -0 "$(cat $vpnpid)" >/dev/null 2>&1; then
	log "inet_check(): openvpn is not running. Starting it."
	openvpn --daemon --config /etc/openvpn/openvpn.conf --writepid "$vpnpid"
fi

if ! ping_probe; then # the connection does not work
	if pgrep pppd >/dev/null 2>&1; then
		log "inet_check(): ping not successful. Stopping pppd..."
		pkill pppd >/dev/null 2>&1
		sleep 10
		pgrep pppd >/dev/null 2>&1 && \
			{ killall -9 pppd >/dev/null 2>&1 # kill if still runs
			log "inet_check(): Killed pppd! o_o"; }
		sleep 5
		log "inet_check(): Resetting modem." 
		modemreset
	elif [ "$modemresetseq" -gt 1 ]; then
		log "inet_check(): Resetting modem (${modemresetseq}th time)."
		modemreset
	else
		log "inet_check(): pppd is not running. Starting it."
		ppp-on -q >/dev/null 2>&1 &
	fi
fi
}

modemreset() {
if gammu reset hard; then
	log "modemreset(): Modem reset successful!"
	modemresetseq=1
	sleep 25

	if ! modem_exists; then return 1; fi

	log "modemreset(): Starting pppd."
	ppp-on -q >/dev/null 2>&1 &
	kill -USR1 "$(cat $vpnpid)"
else
	log "modemreset(): Modem reset NOT successful!"
	((modemresetseq+=1))
fi
}

service_check() {
for service in "${services[@]}"; do # check every service
	pid=$(pgrep "$service")
	if [ "$pid" != "" ] && kill -0 "$pid" >/dev/null 2>&1; then
		continue # this one works, nothing to do
	else
		# give reader some time to start, don't set the fail bit yet
		if [ "$service" = "reader.php" -a \
		"$reader_just_restarted" = 1 ]; then continue; fi
		# else -- a service is dead
		log "service_check(): $service has failed."; fail=1
	fi
done

reader_just_restarted=0 # clear the restart bit

if [ "$fail" == "1" ]; then # at least one service has failed
	((failseq += 1))
	log "service_check(): Failing sequence -- $failseq."

	if [ "$failseq" -eq "3" ]; then
		log "service_check(): Forcing restart."
		failseq=0
		service_restart
		reader_just_restarted=1
	fi
else
	failseq=0 # apparently failing has stopped
fi

fail=0 # reset fail status for the next check cycle

}

service_restart() {
log "service_restart(): Restarting services..."
/etc/rc.d/rc.eib restart && \
log "service_restart(): Success." || log "service_restart(): Failure."
}

#begin
service_start() {
log "$scriptname: Starting."

if [ "$eibwatch" = 1 ]; then # are we watching the services?
for service in "${services[@]}"; do # check if the guys are running
	pgrep "$service" >/dev/null 2>&1 || notrunning=1
done

if [ "$notrunning" = 1 ]; then # (re-)starting the services for good measure
	log "$scriptname: Launching rc.eib."
	/etc/rc.d/rc.eib stop
	/etc/rc.d/rc.eib start
	reader_just_restarted=1 # let reader.php initialize
else
       log "$scriptname: Services seem to be running."
fi
fi

if [ "$inetwatch" = 1 ]; then # if the internetz are started, don't touch them in case this is run remotely.
	if ! modem_exists; then return; fi # don't start if no modem available
	if ! pgrep pppd >/dev/null 2>&1; then
		log "$scriptname: Calling provider..."
		ln -sf /dev/ttyACM? /dev/modem
		ppp-go -q >/dev/null 2>&1; pppstarted=1; fi
	[ -z "$pppstarted" ] && log "$scriptname: Internetz seem to be running."
	if ! kill -0 "$(cat $vpnpid)" >/dev/null 2>&1; then
		log "$scriptname: Starting VPN..."
		modprobe tun >/dev/null 2>&1
		openvpn --daemon --config /etc/openvpn/openvpn.conf --writepid "$vpnpid"
	elif [ "$pppstarted" = "1" ]; then kill -USR1 "$(cat $vpnpid)"; fi
fi
}

# main loop
	service_start
while sleep 3m; do
	[ "$timesync" = 1 ] && timesync
	[ "$eibwatch" = 1 ] && service_check
	[ "$inetwatch" = 1 ] && inet_check
done
