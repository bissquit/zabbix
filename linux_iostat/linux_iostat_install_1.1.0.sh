#!/bin/bash
#=========================================================================
#         FILE: linux_iostat_install_1.1.0.sh
#
#        USAGE: ./linux_iostat_install_1.1.0.sh [ servers DNS/ip ] \
#												[ hostname ]
#
#  DESCRIPTION: 
#
#        NOTES: the scipt has optimized for Debian 9.1. Uncomment Zabbix
#				agent installation if needed.
#       AUTHOR: E.S.Vasilyev - bq@bissquit.com; e.s.vasilyev@mail.ru
#      VERSION: 1.1.0
#      CREATED: 27.10.2017
#=========================================================================

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

#=========================================================================
#  DESCRIPTION: agent installation
#  PARAMETER 1: servers DNS/ip
#  PARAMETER 2: hostname
#=========================================================================
function zabbix_agent_installation {
	apt-get update
	apt-get install zabbix-agent

	sed -i 's/^Server=.*/Server='"$1"'/' "/etc/zabbix/zabbix_agentd.conf"
	sed -i 's/^Hostname=.*/Hostname='"$2"'/' "/etc/zabbix/zabbix_agentd.conf"
}

zabbix_agent_installation "$1" "$2"

#-------------------------------------------------------------------------
# default variables
#-------------------------------------------------------------------------
zabbix_conf_path="/etc/zabbix/zabbix_agentd.conf"	# path to zabbix agent config
[[ -z "$( sed '/^Include=/!d' "$zabbix_conf_path" )" ]] && \
	printf '%s\n' "Include=/etc/zabbix/zabbix_agentd.conf.d/*.conf" >> "$zabbix_conf_path"
zabbix_ext_conf_path="$( sed -rn 's/^Include=(.*)\/.*$/\1/p' $zabbix_conf_path )" # extention configs path
script_log_path="/tmp/linux_iostat_install.sh.log"

exec >/dev/null 2> "$script_log_path"

#-------------------------------------------------------------------------
# sysstat installation ( is mandatory )
#-------------------------------------------------------------------------
apt-get install -y sysstat

#-------------------------------------------------------------------------
# new zabbix agent config creation
#-------------------------------------------------------------------------

mv "${zabbix_conf_path}"{,.orig}

sed '/^[^#]/!d' "${zabbix_conf_path}".orig > "$zabbix_conf_path"
printf '%s\n' "Timeout=30" >> "$zabbix_conf_path"

wget https://raw.githubusercontent.com/bissquit/zabbix/master/linux_iostat/iostat.conf -P "${zabbix_ext_conf_path}"/
wget https://raw.githubusercontent.com/bissquit/zabbix/master/linux_iostat/iostat.data.sh -P "${zabbix_ext_conf_path}"/

chmod a+x "${zabbix_ext_conf_path}"/iostat.data.sh

service zabbix-agent restart
