#!/bin/bash
#=========================================================================
#         FILE: install.sh
#
#        USAGE: ./install.sh
#
#  DESCRIPTION: script performs sysstat installation and configuring.
#               Install and assign template to your host at Zabbix Server
#               before script execution
#
#        NOTES: the scipt has optimized for Debian 9.
#       AUTHOR: E.S.Vasilyev - bq@bissquit.com; e.s.vasilyev@mail.ru
#      VERSION: 1.1.0
#      CREATED: 04.06.2018
#=========================================================================

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

apt-get install -y zabbix-agent

# default path to zabbix agent config
zabbix_conf_path="/etc/zabbix/zabbix_agentd.conf"
# extention configs path
zabbix_ext_conf_path="$( sed -rn 's/^Include=(.*)\/.*$/\1/p' $zabbix_conf_path )"
# script log path
script_log_path="/tmp/linux_iostat_install.sh.log"

exec >/dev/null 2> "$script_log_path"

[[ -z $( sed '/^Include=/!d' "$zabbix_conf_path" ) ]] && \
        { echo 'Error!!! Define Include= option in zabbixs alert config and run install.sh again. Exit...'; exit 1; }

#-------------------------------------------------------------------------
# sysstat installation ( is mandatory )
#-------------------------------------------------------------------------
apt-get install -y sysstat

#-------------------------------------------------------------------------
# zabbix agent config changing
#-------------------------------------------------------------------------
[[ -z $(sed '/^Timeout=.*$/!d' "$zabbix_conf_path") ]] && \
        echo 'Timeout=30' >> "$zabbix_conf_path"

# clean old data
rm ${zabbix_ext_conf_path}/iostat*

# download files
wget https://raw.githubusercontent.com/bissquit/zabbix/master/linux_iostat/iostat.conf -P "${zabbix_ext_conf_path}/"
wget https://raw.githubusercontent.com/bissquit/zabbix/master/linux_iostat/iostat.data.sh -P "${zabbix_ext_conf_path}/"

# replace path
# this is bad idea to use sed as solution. I will think how to replace path more safely
sed -i "s|/path/to/iostat.data.sh|$zabbix_ext_conf_path/iostat\.data\.sh|" "${zabbix_ext_conf_path}/iostat.conf"

chmod a+x "${zabbix_ext_conf_path}/iostat.data.sh"

service zabbix-agent restart
