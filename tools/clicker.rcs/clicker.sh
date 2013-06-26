#!/bin/sh
#
# $Id: clicker.sh,v 1.4 2009/03/23 13:20:35 slava Exp slava $
#
# This script will continiously and randomly click all over your screen until
# it is stopped. Useful for stress-testing programs (full screen type).
# Can also monitor one given process and output it's cpu and mem usage,
# cpu temperature and the number of clicks to a text file for analysis.
# 
#
# Written by CJIy4@u*, 2009.
#

# SET UP -- VARIABLES
# pause between clicks (in microseconds). default: 2000000
CLICK_INTERVAL=2000000
# be verbose about what we do? (errors will be reported regardless). default: 1
VERBOSE=1
# do we want a report? default: 1
REPORT=1
# time interval for writing to the report file? (seconds). default: 10
REPORT_INTERVAL=10
# report process name. default: "flashplayer"
REPORT_PROCESS="flashplayer"
# report output filename. default: "clicker_report"
REPORT_FILE="clicker_report"
# END OF SET UP  

#--------------------------------------------------------
# Check that xautomation is installed
#--------------------------------------------------------

if which xte > /dev/null 2>&1; then
	XTE=$(which xte)
else
cat << _EOT_ >&2
 [Fatal]: The xautomation package is required to be installed.
	  You can get it from your package repository or from
	  http://hoopajoo.net/projects/xautomation.html
_EOT_
exit 1
fi

#--------------------------------------------------------
# Get screen dimensions
#--------------------------------------------------------

if which xdpyinfo > /dev/null 2>&1; then
XDPYINFO=$(which xdpyinfo)

SIZE_HOR=$($XDPYINFO | grep dimensions: | \
	awk {'print $2'} | cut -d 'x' -f1)
SIZE_VER=$($XDPYINFO | grep dimensions: | \
        awk {'print $2'} | cut -d 'x' -f2)

elif [ "$SIZE_HOR" = "" -o "$SIZE_VER" = "" ]; then
cat << _EOT_ >&2
 [Error]: Could not get the dimensions of your screen.
	  Please install xdpyinfo or provide screen dimensions manually.
	  Example: SIZE_HOR=1024 SIZE_VER=768 $0
_EOT_
exit 1

fi

#--------------------------------------------------------
# The mighty randomBetween function from the ABS. (tldp.org)
# Edited for space. Copyright Bill Gradwohl, 2003.
#--------------------------------------------------------

randomBetween() {
   #  Bill Gradwohl - Oct 1, 2003

   syntax() {
      echo    "Syntax: randomBetween [min] [max] [multiple]"
   }

   local min=${1:-0}
   local max=${2:-32767}
   local divisibleBy=${3:-1}
   # Default values assigned, in case parameters not passed to function.

   local x
   local spread

   # Let's make sure the divisibleBy value is positive.
   [ ${divisibleBy} -lt 0 ] && divisibleBy=$((0-divisibleBy))

   # Sanity check.
   if [ $# -gt 3 -o ${divisibleBy} -eq 0 -o  ${min} -eq ${max} ]; then 
      syntax
      return 1
   fi

   # See if the min and max are reversed.
   if [ ${min} -gt ${max} ]; then
      # Swap them.
      x=${min}
      min=${max}
      max=${x}
   fi

   #  If min is itself not evenly divisible by $divisibleBy,
   #+ then fix the min to be within range.
   if [ $((min/divisibleBy*divisibleBy)) -ne ${min} ]; then 
      if [ ${min} -lt 0 ]; then
         min=$((min/divisibleBy*divisibleBy))
      else
         min=$((((min/divisibleBy)+1)*divisibleBy))
      fi
   fi

   #  If max is itself not evenly divisible by $divisibleBy,
   #+ then fix the max to be within range.
   if [ $((max/divisibleBy*divisibleBy)) -ne ${max} ]; then 
      if [ ${max} -lt 0 ]; then
         max=$((((max/divisibleBy)-1)*divisibleBy))
      else
         max=$((max/divisibleBy*divisibleBy))
      fi
   fi

   #  Now, to do the real work.
   spread=$((max-min))
   [ ${spread} -lt 0 ] && spread=$((0-spread))
   let spread+=divisibleBy
   randomBetweenAnswer=$(((RANDOM%spread)/divisibleBy*divisibleBy+min))   

   return 0
}

#--------------------------------------------------------
# Function to write a system info report to a text file
#--------------------------------------------------------

write_report () {

clean_old_report () {

if [ ! -f "$REPORT_FILE" ]; then
	[ $VERBOSE = 1 ] && echo "creating a new report file"
	touch $REPORT_FILE
	CLEANED=1
elif [ -f "$REPORT_FILE" -a "$CLEANED" = "" ]; then
	[ $VERBOSE = 1 ] && echo "removing a stale report file"
	rm $REPORT_FILE
	CLEANED=1
fi
}

if [ $REPORT_PROCESS != "" ]; then
	if pgrep $REPORT_PROCESS > /dev/null 2>&1; then
		CPU_LOAD=$(ps aux | grep $REPORT_PROCESS | head -n1 | awk {'print $3'})
		MEM_LOAD=$(ps aux | grep $REPORT_PROCESS | head -n1 | awk {'print $4'})
		CPU_TEMP=$(cat /proc/acpi/thermal_zone/*/temperature | head -n1 | awk {'print $2'})
		clean_old_report
		echo "$TIME $CLICKS $REPORT_PROCESS $CPU_LOAD $MEM_LOAD $CPU_TEMP" >> $REPORT_FILE
		[ $VERBOSE = 1 ] && echo "wrote report"
	else
		echo "your process to monitor is defined as $REPORT_PROCESS, but it is not running." >&2
		echo "exiting now..." >&2
		exit 1
	fi
else
	echo "you opted for writing a report but you did not define a process to monitor." >&2
	echo "exiting now..." >&2
	exit 1
fi
}

#--------------------------------------------------------
# Starting the main job...
#--------------------------------------------------------

if [ $VERBOSE = 1 ]; then
	echo -e "\nStarting [ $(basename $0) ] in verbose mode..."
	echo "Click interval: $CLICK_INTERVAL useconds."
	if [ $REPORT = 1 ]; then
	echo -e "Checking $REPORT_PROCESS every $REPORT_INTERVAL seconds; Output to $REPORT_FILE.\n"
	else echo -e "Report: none.\n"
	fi
fi

LAST_WRITE_TIME=0
CLICKS=0

while true; do

randomBetween 0 $SIZE_HOR; hor=$randomBetweenAnswer
randomBetween 0 $SIZE_VER; ver=$randomBetweenAnswer

[ $VERBOSE = 1 ] && echo "$hor $ver"

$XTE "mousemove $hor $ver" #'mouseclick 1'

CLICKS=$(( $CLICKS + 1 ))
[ $VERBOSE = 1 ] && echo "clicks made: $CLICKS"

if [ $REPORT = 1 ]; then
	TIME=$(date +%s)
	if [ $(( $TIME - $LAST_WRITE_TIME )) -gt "$REPORT_INTERVAL" ]; then
		write_report
		LAST_WRITE_TIME=$TIME
	fi
fi

usleep "$CLICK_INTERVAL"

done

#end
