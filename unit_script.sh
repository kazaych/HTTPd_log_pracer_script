#!/bin/bash

#Delete all temp files in case of unexpected stop the script

function clean {
        echo "Deleting temp files"
        rm -f tmp.log && rm -f /var/lock/unit_script.lock && rm -f last_launch.log
        echo "Success"
}

trap clean 1 2 3 6 15

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

if [ ! -s tmp.log ]
then
cat <<-EOF > result.log 
	--------------------------------------------------------------
	 This log create from `cat last_launch.log | sed 's/\[//'` to `date -d'now' +%d/%b/%Y:%H:%M:%S`	
	--------------------------------------------------------------
	There is nothing to change
EOF
else
cat <<-EOF > result.log  
	--------------------------------------------------------------
	This log create from `cat last_launch.log | sed 's/\[//'` to `date -d'now' +%d/%b/%Y:%H:%M:%S`
	--------------------------------------------------------------
	'----- MAXIUMUM IP COUNT -----'
	$(best_ip)
	'----- MAXIMUM WWW COUNT -----'
	$(best_http)
	'----- HTTP CODE COUNT -------'
	$(http_codes)
	'----- HTTP ERRORS COUNT -----'
	$(http_bad_codes)
EOF
	rm -f tmp.log
fi

# Delete environment
rm -f /var/lock/unit_script.lock

# Create and send email 

mail -a ./result.log -s "Log file from httpd" kazay@mail.ru < /dev/null
