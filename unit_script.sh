#!/bin/bash


# Test file exist andt and log last launch script create

if test -r last_launch.log; then

	date +"[%d/%b/%Y:%H:%M" > last_launch.log
else
	echo [14/Aug/2019:00:00:00 > last_launch.log
fi

LOG=$1


# Parse time range between time in last_launch.log and current time, check that input httpd access.log contain only strings in time range
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


# Output

valid_time $LOG

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
	rm -f tmp.log
fi
