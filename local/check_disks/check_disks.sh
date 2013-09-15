#!/bin/sh
######################################################################
# Description:
#   check_disks.sh
######################################################################
# Changelog:
# v0.1 - 2013-09-14 - Mathieu MD
#   Creation
#   Based on Thiago Varela <thiago@iplenix.com> check_disk v0.0.2
#   http://exchange.nagios.org/directory/Plugins/Operating-Systems/Linux/check_disk--2D-%25-used-space/details
######################################################################

help() {
    cat <<EOF
This plugin shows the % of used space of a mounted partition, using the 'df' utility

$0:
    -c <integer>    If the % of used space is above <integer>, returns CRITICAL state
    -w <integer>    If the % of used space is below CRITICAL and above <integer>, returns WARNING state
    -d <devices>    The space separated list of partitions or mountpoints to be checked.
                    eg. "/ /home /var" or "/dev/sda1"
EOF
    exit 3
}

TITLE="Free Space"

msg="UNKNOWN"
status=3
txt=""
perfdata=""

######################################################################

# Getting parameters:
while getopts "d:w:c:h" OPT; do
    case $OPT in
        "d") devices=$OPTARG;;
        "w") warning=$OPTARG;;
        "c") critical=$OPTARG;;
        "h") help;;
    esac
done

# Checking parameters:
if [ "$warning" = "" ]; then
    warning=90
fi
if [ "$critical" = "" ]; then
    critical=95
fi
if [ "$warning" -ge "$critical" ]; then
    echo "ERROR: Critical level must be highter than warning level"
    help
fi
if [ "$devices" = "" ]; then
    devices=$(df -P | tail -n+2 | grep -v ^tmpfs | grep -v ^udev | awk '{print $6}')
fi

######################################################################

for device in $devices; do
    if ! df -P $device >/dev/null 2>&1; then
        echo "ERROR: No such device '$device'!"
        help
    fi

    # Get infos through a single call to df
    info=$(df -Ph $device | tail -n1)
    size=$(echo $info | awk '{print $2}')
    used=$(echo $info | awk '{print $3}')
    avail=$(echo $info | awk '{print $4}')
    usedp=$(echo $info | awk '{print $5}' | cut -d"%" -f1)

    # Comparing the result and setting the correct level:
    if [ $usedp -ge $critical ]; then
        txt="$txt - Only $avail/$size on '$device'"
        msg="CRITICAL"
        status=2
    elif [ $usedp -ge $warning ]; then
        txt="$txt - $avail/$size on '$device'"
        if [ $status -ne 2 ]; then
            msg="WARNING"
            status=1
        fi
    else
        if [ $status -eq 3 ]; then
            msg="OK"
            status=0
        fi
    fi

    perfdata="$perfdata '$device usage'=$usedp%;$warning;$critical;"
done

# Printing the results:
echo "$TITLE ${msg}$txt |$perfdata"
# Exiting with status
exit $status
