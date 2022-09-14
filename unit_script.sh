#!/bin/bash

# Prevent dublicate start

if [ -e "/var/lock/unit_script.lock" ]; then
    echo "Another instance of the script is running. Aborting."
    exit
else
    touch  "/var/lock/unit_script.lock"
fi


# Test file exist and log last launch script create

if test -r last_launch.log; then

	date +"[%d/%b/%Y:%H:%M" > last_launch.log
else
	echo [14/Aug/2019:00:00:00 > last_launch.log
fi

LOG=$1


# Parse time range between time in last_launch.log and current time, write range of strings in time range to tmp.log file
function valid_time {
	touch tmp.log
	awk -vSTART_Date=`cat last_launch.log` -vEND_Date=`date -d'now' +[%d/%b/%Y:%H:%M:%S` '$4 > START_Date && $4 < END_Date {print $0}' $1 > tmp.log
}

# Parse 3 ip addresses from access.log after cut range of time with valid_time
function best_ip {
	cat tmp.log | cut -f 1 -d '-' | sort | uniq -c | sort -n | tail -n 3 | awk '{print $2,"-",$1}'
}

# Parse 3 best http  from access.log after cut range of time with valid_time
function best_http {
	cat tmp.log | awk '/GET/ {print $15}' | grep http | cut -f 1 -d ')' | sort | sed 's/+//' | uniq -c | sort -n | awk '{print $2,"-",$1}' | tail -n 3
}

# Parse HTTP Code

function http_codes {
	cat access.log | grep GET | awk '{print $9}' | sort | uniq -c | awk '{print $2"-"$1}' | sort -n	
}

function http_bad_codes {
	cat access.log | grep GET | awk '{print $9}' | sort | uniq -c | awk '{print $2"-"$1}' | sort -n | awk -vCOD=399 '$1 > COD {print $0}'
}
# Start valid_time function

valid_time $LOG

# Output

if [ ! -s tmp.log ]; then
	echo --------------------------------------------------------------
	echo This log create from `cat last_launch.log | sed 's/\[//'` to `date -d'now' +%d/%b/%Y:%H:%M:%S`
	echo --------------------------------------------------------------
	echo There is nothing to change
else 
	echo --------------------------------------------------------------
        echo This log create from `cat last_launch.log | sed 's/\[//'` to `date -d'now' +%d/%b/%Y:%H:%M:%S`
        echo --------------------------------------------------------------	
	echo '----- MAXIUMUM IP COUNT -----'
	best_ip
	echo '----- MAXIMUM WWW COUNT -----'
	best_http
	echo '----- HTTP CODE COUNT -------'
	http_codes
	echo '----- HTTP ERRORS COUNT -----'
	https_bad_codes
	rm -f tmp.log
fi

# Delete environment
rm -f /var/lock/unit_script.lock

# Create and sen email 

touch "result.log"
cmd >> ./result.log  2>&1

mail -a ./result.log -s "log file from httpd `cat last_launch.log | sed 's/\[//'` to `date -d'now' +%d/%b/%Y:%H:%M:%S`" kazay@mail.ru < /dev/null 



