#!/bin/bash
#=========================================================================
#         FILE: iostat.data.sh
#
#        USAGE: ./iostat.data.sh [ file with iostat output data ] \
#				 [ disk name (such as sda, hda, etc.) ] \
#				 [ iostat column. e.g. rrqm/s, r/s etc. ]
#
#  DESCRIPTION: input - file with iostat output with 1 second interval
#               output - single floating-point number for ZABBIX Server
#
#        NOTES: use this script with zabbix template, not by itself
#       AUTHOR: E.S.Vasilyev - bq@bissquit.com; e.s.vasilyev@mail.ru
#      VERSION: 1.0.1
#      CREATED: 18.10.2017
#=========================================================================

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

iostat_refresh=60	# iostat ouput file refresh time in seconds
param_column=0		# the number of iostat output column
date_diff=0		# difference between two dates in seconds

#-------------------------------------------------------------------------
# chech file exist and comparation of current time with last file
# modification time
#-------------------------------------------------------------------------
if [ -f $1 ] ; then
	#get difference between (current time) and (the last file modification time):
	let " date_diff = \
		$( date +'%s' -d "$(date +"%Y/%m/%d %H:%M:%S")" ) - \
		$( date +'%s' -d "$(stat $1 | sed -r '6!d;s/^.*([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}).*/\1/')" ) \
		"
	if (( date_diff > iostat_refresh )) ; then
		iostat -d -x > $1
	fi
else
	iostat -d -x > $1
fi

#-------------------------------------------------------------------------
# case third param (disk metric)
# and get needed column with awk
#-------------------------------------------------------------------------
case $3 in
	"rrqm/s")
		param_column=2
	;;
	"wrqm/s")
		param_column=3
	;;
	"r/s")
		param_column=4
	;;
	"w/s")
		param_column=5
	;;
	"rkB/s")
		param_column=6
	;;
	"wkB/s")
		param_column=7
	;;
	"avgrq-sz")
		param_column=8
	;;
	"avgqu-sz")
		param_column=9
	;;
	"await")
		param_column=10
	;;
	"r_await")
		param_column=11
	;;
	"w_await")
		param_column=12
	;;
	"svctm")
		param_column=13
	;;
	"%util")
		param_column=14
	;;
	*)
		printf '%s\n' "invalid param!"
	;;
esac

#-------------------------------------------------------------------------
# you may be confused with awk command parameters below: $1 inside single
# quotes - its awks column number. But $1 after awk command - its first
# bash input variable (file with iostat output data)
#-------------------------------------------------------------------------
awk -v a_disk_name="$2" -v a_param_column="$param_column" '$1 ~ a_disk_name {sub(",",".",$a_param_column);print $a_param_column}' $1
