#!/usr/bin/env bash

#set -e 
#set -u


# Software install
# ----------------
#
# Utilities
#

#
# JRE
#
yum -y install java-1.7.0
#
# Rundeck 
#
if ! rpm -q rundeck-repo
then
    rpm -Uvh http://repo.rundeck.org/latest.rpm 
fi
if -f /vagrant/rundeck.rpm
then
    rpm -ivh /vagrant/rundeck.rpm /vagrant/rundeck-config.rpm
else
    yum -y install rundeck
fi


# Reset the home directory permission as it comes group writeable.
# This is needed for ssh requirements.
chmod 755 ~rundeck

# Configure the system
#

#
# Disable the firewall so we can easily access it from the host
service iptables stop
#


# Start up rundeck
# ----------------
#
mkdir -p /var/log/vagrant
if ! /etc/init.d/rundeckd status
then
    echo "Starting rundeck..."
    (
        exec 0>&- # close stdin
        /etc/init.d/rundeckd start 
    ) &> /var/log/rundeck/service.log # redirect stdout/err to a log.

    let count=0
    let max=18
    while [ $count -le $max ]
    do
        if ! grep  "Started SelectChannelConnector@" /var/log/rundeck/service.log
        then  printf >&2 ".";# progress output.
        else  break; # successful message.
        fi
        let count=$count+1;# increment attempts
        [ $count -eq $max ] && {
            echo >&2 "FAIL: Execeeded max attemps "
            exit 1
        }
        sleep 10
    done
fi

echo "Rundeck started."

exit $?
