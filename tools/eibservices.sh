#!/bin/sh
# Cron this every 5 minutes to check for any fallen eib services
# and to correct the time on the bus
#
# TODO: Set the exec interval in /var/spool/cron/crontabs/root

if [ -x /usr/local/bin/eibwatch.sh ]; then
	/usr/local/bin/eibwatch.sh check
fi

sleep 10

if [ -f /usr/local/eib/timesync.php ]; then
	php /usr/local/eib/timesync.php
fi
