#!/bin/bash
################################################################################
# Creation:  2012-08-07 - Mathieu MD
# Based on Sebastian Grewe's check_traffic.sh from http://is.gd/uXvK3R
# Changelog: 
################################################################################
# Description:
#
# Nagios plugin to check bandwidth traffic on all network devices.
#
################################################################################

TITLE="TRAFFIC"
VERSION="v0.1 (2012-08-07)"
AUTHOR="2012, Mathieu MD <mathieu.md@gmail.com>"

PROGNAME=$(basename $0)

# To get normalized output (Awk in French return a "," as decimal dot)
LANG=C

# Exit codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Safe values
interfaces=all
sec_sample=5
unit="b/s"
bytes_multiplier=8
bits_multiplier=1
verbose=0

PROCNETDEV="/proc/net/dev"

################################################################################

# Print the revision number
print_revision() {
    echo "$PROGNAME - $VERSION"
}

# Print a short usage statement
print_usage() {
    echo "Usage:"
    echo "$PROGNAME [-v] -w <rx>[:<tx>] -c <rx>[:<tx>] [-i <interfaces>] [-B] [-s <sec>]"
}

# Print detailed help information
print_help() {
    print_revision
    echo -e "$AUTHOR\n\nCheck traffic on all network devices on the local machine\n"
    print_usage

    /bin/cat <<__EOT

Options:
  -h    Print detailed help screen.
  -V    Print version information.
  -v    Enable verbose display (repeat to increase verbosity).
  -w RX_LIMIT[:TX_LIMIT]
        Warning exit status if in(rx) or out(tx) traffic is higher.
  -c RX_LIMIT[:TX_LIMIT]
        Critical exit status if in(rx) or out(tx) traffic is higher.
  -i INTERFACES [default: all]
        Comma separated list of interfaces to limit to.
  -B
        Results are shown in bytes/s (B/s) instead of bits/s (b/s).
  -s SECONDS [default: 5]
        Duration (in seconds) to wait to get the traffic sample.

If TX_LIMIT is not set, it's value is the same as RX_LIMIT's.
TX_LIMIT and RX_LIMIT may be followed by a multiplier (k, M, G and T).
__EOT
}

################################################################################

# Adjust kMG units to b
adjust_unit() {
    _value=$(echo $* | sed 's/[ kMGTb/ps]//g')
    _unit=$(echo $* | sed 's/[ 0-9]//g')
    case "$_unit" in
        k|kb/s|kbps)
            echo $(($_value*1000))
            ;;
        M|Mb/s|Mbps)
            echo $(($_value*1000*1000))
            ;;
        G|Gb/s|Gbps)
            echo $(($_value*1000*1000*1000))
            ;;
        T|Tb/s|Tbps)
            echo $(($_value*1000*1000*1000*1000))
            ;;
        *)
            echo $_value
            ;;
    esac
}

# Create the status string for all the devices found
status() {
    DEV=$1
    COUNT=$2
    MSG_V="$MSG_V $DEV RX:${RXS[$COUNT]} "
    if [[ ${RXS[$COUNT]} -lt $warn_rx ]]; then
        [[ $STATUS != "WARNING" ]] && [[ $STATUS != "CRITICAL" ]] && STATUS="OK"
        [[ $EXIT != $STATE_CRITICAL && $EXIT != $STATE_WARNING ]] && EXIT=$STATE_OK
    elif [[ ${RXS[$COUNT]} -lt $crit_rx ]]; then
        MSG_V="$MSG_V (WARN)"
        MSG="$MSG $DEV RX:${RXS[$COUNT]} $unit  WARN,"
        [[ $STATUS != "CRITICAL" ]] && STATUS="WARNING"
        [[ $EXIT != $STATE_CRITICAL ]] && EXIT=$STATE_WARNING
    elif [[ ${RXS[$COUNT]} -ge $crit_rw ]]; then
        MSG_V="$MSG_V (CRIT)"
        MSG="$MSG $DEV RX:${RXS[$COUNT]} $unit CRIT,"
        STATUS="CRITICAL"
        EXIT=$STATE_CRITICAL
    fi
    MSG_V="$MSG_V TX:${TXS[$COUNT]} $unit "
    if [[ ${TXS[$COUNT]} -lt $warn_tx ]]; then
        [[ $STATUS != "WARNING" ]] && [[ $STATUS != "CRITICAL" ]] && STATUS="OK"
        [[ $EXIT != $STATE_CRITICAL && $EXIT != $STATE_WARNING ]] && EXIT=$STATE_OK
    elif [[ ${TXS[$COUNT]} -lt $crit_tx ]]; then
        MSG_V="$MSG_V (WARN)"
        MSG="$MSG $DEV TX:${TXS[$COUNT]} $unit WARN,"
        [[ $STATUS != "CRITICAL" ]] && STATUS="WARNING"
        [[ $EXIT != $STATE_CRITICAL ]] && EXIT=$STATE_WARNING
    elif [[ ${TXS[$COUNT]} -ge $crit_tx ]]; then
        MSG_V="$MSG_V (CRIT)"
        MSG="$MSG $DEV TX:${TXS[$COUNT]} $unit CRIT,"
        STATUS="CRITICAL"
        EXIT=$STATE_CRITICAL
    fi
    MSG_V="$MSG_V,"
}

################################################################################

while test -n "$1"; do
    case "$1" in
        --help|-h)
            print_help
            exit $STATE_UNKNOWN
            ;;
        -\?)
            print_usage
            exit $STATE_UNKNOWN
            ;;
        --version|-V)
            print_revision
            exit $STATE_UNKNOWN
            ;;
        --verbose|-v)
            verbose=$(($verbose+1))
            ;;
        -vv)
            verbose=$(($verbose+2))
            ;;
        --warning|-w)
            if [[ $(echo $2 | grep ':' -c1) -eq 1 ]]; then
                warn_rx_=$(echo $2 | cut -d: -f1)
                warn_tx_=$(echo $2 | cut -d: -f2)
            else
                warn_rx_=$2
                warn_tx_=$2
            fi
            shift
            ;;
        --critical|-c)
            if [[ $(echo $2 | grep ':' -c1) -eq 1 ]]; then
                crit_rx_=$(echo $2 | cut -d: -f1)
                crit_tx_=$(echo $2 | cut -d: -f2)
            else
                crit_rx_=$2
                crit_tx_=$2
            fi
            shift
            ;;
        --interfaces|-i)
            interfaces=$2
            shift
            ;;
        --bytes|-B)
            bytes_multiplier=1
            bits_multiplier=8
            unit="B/s"
            ;;
        --seconds|-s)
            sec_sample=$2
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            print_help
            exit $STATE_UNKNOWN
            ;;
    esac
    shift
done

if [[ ! -r $PROCNETDEV ]]; then
    echo "$PROGNAME: Cannot open $PROCNETDEV"
    exit $STATE_UNKNOWN
fi

if [[ -z "$sec_sample" ]]; then
    echo "$PROGNAME: Duration of the sample cannot be empty"
    print_usage
    exit $STATE_UNKNOWN
fi

if [[  -z "$warn_rx_" || -z "$crit_rx_"
    || -z "$warn_tx_" || -z "$crit_tx_" ]]; then
    echo "$PROGNAME: WARNING and/or CRITICAL values must be defined"
    print_usage
    exit $STATE_UNKNOWN
fi

warn_rx=$(adjust_unit $warn_rx_)
crit_rx=$(adjust_unit $crit_rx_)
warn_tx=$(adjust_unit $warn_tx_)
crit_tx=$(adjust_unit $crit_tx_)

if [[  $(echo $warn_rx | egrep "^[0-9]+$" -c) -ne 1
    || $(echo $crit_rx | egrep "^[0-9]+$" -c) -ne 1
    || $(echo $warn_tx | egrep "^[0-9]+$" -c) -ne 1
    || $(echo $crit_tx | egrep "^[0-9]+$" -c) -ne 1  ]]; then
    echo "$PROGNAME: WARNING and CRITICAL values must be valid integers (and"
    echo "may be suffixed with k, M, G or T)"
    print_usage
    exit $STATE_UNKNOWN
fi

if [[  ! $warn_rx -ge 0 || ! $crit_rx -ge 0
    || ! $warn_tx -ge 0 || ! $crit_tx -ge 0 ]]; then
    echo "$PROGNAME: WARNING and CRITICAL values must be positive integers"
    print_usage
    exit $STATE_UNKNOWN
fi

if [[  $warn_rx -gt $crit_rx
    || $warn_tx -gt $crit_tx ]]; then
    echo "$PROGNAME: Values of WARNING must be lower than CRITICAL"
    print_usage
    exit $STATE_UNKNOWN
fi

if [[ -z "$interfaces" ]]; then
    echo "$PROGNAME: Interfaces value cannot be empty"
    print_usage
    exit $STATE_UNKNOWN
fi

if [[ "$interfaces" == "all" ]]; then
    # Get all interfaces with a MAC address
    INTERFACES=$(/sbin/ifconfig | grep HWaddr | awk '{print $1}')
else
    INTERFACES=$(echo $interfaces | sed 's/,/ /g')
    for i in $INTERFACES; do
        if [[ $(grep -c "^[[:space:]]*$i:" $PROCNETDEV) -ne 1 ]]; then
            echo "$PROGNAME: Interface \"$i\" do not exist"
            print_usage
            exit $STATE_UNKNOWN
        fi
    done
fi


################################################################################

# Parse traffic for each interfaces
COUNT1=0
for interface in $INTERFACES; do
    RAW1[$COUNT1]=$(grep "^[[:space:]]*$interface:" $PROCNETDEV)
    INT1[$COUNT1]=$(echo ${RAW1[$COUNT1]} | cut -d: -f2)
    RX1[$COUNT1]=$(echo ${INT1[$COUNT1]} | awk '{print $1}')
    TX1[$COUNT1]=$(echo ${INT1[$COUNT1]} | awk '{print $9}')
    COUNT1=$((COUNT1+1))
done

# Wait to get a diff in rx and tx totals
sleep $sec_sample

# Parse it again to calculate b/s
COUNT2=0
for interface in $INTERFACES; do
    # Get traffic again
    RAW2[$COUNT2]=$(grep "^[[:space:]]*$interface:" $PROCNETDEV)
    INT2[$COUNT2]=$(echo ${RAW2[$COUNT2]} | cut -d: -f2)
    RX2[$COUNT2]=$(echo ${INT2[$COUNT2]} | awk '{print $1}')
    TX2[$COUNT2]=$(echo ${INT2[$COUNT2]} | awk '{print $9}')

    SPEED[$COUNT2]=$(dmesg 2>/dev/null | grep "$interface: Link is up at " | tail -n1 | sed 's/Link is up at /,/' | cut -d, -f2)
    SPEED_VALUE[$COUNT2]=$(echo ${SPEED[$COUNT2]} | awk '{print $1}')
    SPEED_UNIT[$COUNT2]=$(echo ${SPEED[$COUNT2]} | awk '{print $2}')
    tmpmax=$(adjust_unit ${SPEED[$COUNT2]})

    # Make temp values with total transferred kb/s
    tmprx=$(( ${RX2[$COUNT2]}-${RX1[$COUNT2]} ))
    tmptx=$(( ${TX2[$COUNT2]}-${TX1[$COUNT2]} ))

    # Convert bytes to bits (if requested)
    # Totals are in bytes, but max speed is already in bits
    tmprx=$(( $tmprx*$bytes_multiplier))
    tmptx=$(( $tmptx*$bytes_multiplier))
    [[ $tmpmax -gt 0 ]] && tmpmax=$(( $tmpmax/$bits_multiplier))

    # Compute to get the traffic/second
    tmprx=$(( $tmprx/$sec_sample ))
    tmptx=$(( $tmptx/$sec_sample ))

    # Fill into array
    RXS[$COUNT2]=$tmprx
    TXS[$COUNT2]=$tmptx
    MAX[$COUNT2]=$tmpmax

    # Generate status output
    status $interface $COUNT2
    PERFORMANCE="$PERFORMANCE ${DEV}-rx=${RXS[$COUNT2]}$unit;$warn_rx;$crit_rx;;${MAX[$COUNT2]} ${DEV}-tx=${TXS[$COUNT2]}$unit;$warn_tx;$crit_tx;;${MAX[$COUNT2]}"
    COUNT2=$((COUNT2+1))
done

if [[ $COUNT2 -gt 1 ]]; then
    TOTAL_INTERFACES="($COUNT2 interfaces checked) "
fi

if [[ $verbose -ge 1 ]]; then
    MSG="- $(echo $MSG_V | sed 's/,$//') "
elif [[ $MSG ]]; then
    MSG="- $(echo $MSG | sed 's/,$//') "
fi

# do the Nagios magic
echo "$TITLE ${STATUS} ${MSG}${TOTAL_INTERFACE}|$PERFORMANCE"

if [[ $verbose -ge 2 ]]; then
    cat << EOT__
Debugging information:
  Unit: $unit (bytes multiplier = $bytes_multiplier, bits multiplier = $bits_multiplier)
  Interface(s): $INTERFACES $TOTAL_INTERFACES
  Speed(s): ${SPEED[*]}
  RX Warning threshold: $warn_rx (user input: $warn_rx_)
  TX Critical threshold: $crit_tx (user input: $crit_tx_)
  Verbosity level: $verbose
  Raw output:
  - 1st iteration:
${RAW1[*]}
  - 2nd iteration (after $sec_sample seconds):
${RAW2[*]}
EOT__
fi

exit $EXIT
