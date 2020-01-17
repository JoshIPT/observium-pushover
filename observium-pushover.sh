#!/bin/bash -x
# observium-pushover.sh
# Written by Josh Finlay <josh.f@iptelco.com.au>
#
# Based on Slack Alert code written by Bruce Forster <bruce@bestpath.com.au>
#
# ---------------------------------------
# Pushover tokens used for authentication
# ---------------------------------------
# App token:
TOKEN=""
# User/delivery group token:
USERTOKEN=""

### REAL VARS
LOG="logger -s -p local0.notice -i -t $0"
INPUT=`echo $OBSERVIUM_SYSLOG_MESSAGE`
INTERFACE=`echo $INPUT | grep -o -E "[0-9]{1,2}[A-Z]{2}[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{1,2}"`
#
# Lets make sure OBSERVIUM_DURATION has some data to use if not lets use OBSERVIUM_TIMESTAMP
# If all else fails, lets use a current date/time stamp.
#
if [[ -n $OBSERVIUM_DURATION ]] ; then
    TIMESTAMP=$OBSERVIUM_DURATION
elif [[ -n $OBSERVIUM_TIMESTAMP ]] ; then
    TIMESTAMP=$OBSERVIUM_TIMESTAMP
else
    TIMESTAMP=`date +'%d/%m/%Y %I:%M:%S%p'`
fi

# If we are alerting on the first instance (ie. Observium delay set to 0), we get "Unknown" as a duration. This is useless, we want to know now.
if [ "$TIMESTAMP" == "Unknown" ] ; then
    TIMESTAMP=`date +'%d/%m/%Y %I:%M:%S%p'`
fi

#
# Lets sort though what were getting...
#
if [[ $OBSERVIUM_ALERT_STATE =~ ALERT ]] ; then
    STATE="ALERT"
    TYPE=`echo $OBSERVIUM_METRICS`
    PRIO=1
    TOPUSHOVER="Message: $OBSERVIUM_MESSAGE
Interface: $OBSERVIUM_ENTITY_NAME
Details: $OBSERVIUM_CONDITIONS
Description: $OBSERVIUM_ENTITY_DESCRIPTION
Duration/Time: $TIMESTAMP"
elif [[ $OBSERVIUM_ALERT_STATE =~ RECOVER ]] ; then
    STATE="RECOVER"
    TYPE=`echo $OBSERVIUM_METRICS`
    PRIO=0
    TOPUSHOVER="Interface: $OBSERVIUM_ENTITY_NAME
Details: $OBSERVIUM_ENTITY_DESCRIPTION
Duration/Time: $TIMESTAMP"
elif [[ $OBSERVIUM_ALERT_STATE =~ SYSLOG ]] ; then
    STATE="SYSLOG"
    TYPE="SYSLOG"
    PRIO=0
    TOPUSHOVER="Regex: $OBSERVIUM_SYSLOG_RULE
Match: $OBSERVIUM_SYSLOG_MESSAGE
Duration/Time: $TIMESTAMP"
fi
#
# Lets make sure we have something useful to send before we do anything more..
#
if [[ -z $STATE ]] ; then
    $LOG "$0 No message sent because STATE NOT SET, here is what I know: $OBSERVIUM_DEVICE_HOSTNAME $TOPUSHOVER $STATE $TIMESTAMP"
    STATE="ERR"
    TOPUSHOVER="STATE NOT SET!! Here is what I know:
Hostname: $OBSERVIUM_DEVICE_HOSTNAME
Message: $OBSERVIUM_MESSAGE
State: $STATE
Duration: $TIMESTAMP
URL: $OBSERVIUM_ALERT_URL"
fi

#Push to Pushover API

curl -X POST \
        --data-urlencode "token=$TOKEN" \
        --data-urlencode "user=$USERTOKEN" \
        --data-urlencode "message=$TOPUSHOVER" \
        --data-urlencode "title=$OBSERVIUM_TITLE" \
        --data-urlencode "priority=$PRIO" \
        --data-urlencode "monospace=1" \
        https://api.pushover.net/1/messages.json
