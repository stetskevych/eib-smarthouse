#!/bin/bash
#
# We will feed this to cron to periodically watch if the eib toolset is online.

logfile="/var/log/eibwatch.log"
statfile="/tmp/eibwatch.stat"
fail=0

log() {
	echo "$(/bin/date "+%F %T"): $1" >> $logfile
}

check() {
if pgrep pppd >/dev/null 2>&1; then
	if ! ping -c1 www.google.com >/dev/null 2>&1; then
		log "check(): ping not successful. Stopping pppd..."
		pkill -HUP pppd && log "check(): SIGHUP succeeded." \
		|| log "check(): SIGHUP failed!"
		sleep 3
		pkill -TERM pppd && log "check(): SIGTERM succeeded." \
		|| log "check(): SIGTERM failed!"
		sleep 3
		if pgrep pppd >/dev/null 2>&1; then
			pkill -KILL pppd && log "check(): SIGKILL succeeded." \
			|| log "check(): SIGKILL failed!"
		fi
#			ttynum=0
#		until gammu reset hard; do
#			if [ "$ttynum" -lt 10 ]; then
#				((ttynum+=1))
#			else
#				log "check(): Can not reset modem!!"
#			fi
#			ln -sf /dev/ttyACM${ttynum} /dev/modem
#		done
#		log "check(): Modem has been reset."

		gammu reset hard && log "check(): Modem reset successful!" \
		|| log "check(): Modem reset NOT successful!"
		sleep 30
		ppp-on >/dev/null 2>&1 &
		pkill -USR1 openvpn
	fi
else
	log "check(): pppd is not running. Starting it."
	ppp-on >/dev/null 2>&1 &
fi

if ! pgrep openvpn >/dev/null 2>&1; then
	log "check(): openvpn is not running. Starting it."
	openvpn --daemon --config /etc/openvpn/openvpn.conf
fi

for service in "eibd" "server.php" "reader.php"; do
	pid=$(pgrep "$service")
	if [ "$pid" != "" ] && kill -0 "$pid" >/dev/null 2>&1; then
		continue
	else
		log "check(): $service has failed."; fail=1
	fi
done	

if [ "$fail" == "1" ]; then
	if [ ! -f "$statfile" ]; then
	echo "0" > "$statfile"; fi
	read failseq <"$statfile"
	((failseq += 1))

	log "check(): Failing sequence -- $failseq."

	if [ "$failseq" -eq "3" ]; then
		log "check(): Forcing restart."
		echo "0" > "$statfile"
		restart
	else
		echo "$failseq" > "$statfile"
	fi
else
	echo "0" > "$statfile"
fi

}

restart() {

log "restart(): Restarting services..."
/etc/rc.d/rc.eib restart && \
log "restart(): Success." || log "restart(): Failure."

}

case "$1" in
  'check')   
    check
  ;;
  *)
    echo "Usage: $0 check"
    exit 1
  ;;
esac
