#!/bin/bash
################################################################################
# Creation:  2012-08-02 - Mathieu MD
# An Awk code part is from castorpilot: http://is.gd/D3ksZw
# Changelog: 
################################################################################
# Description:
#
# A Nagios/Shinken plugin to monitor CPU usage by each users.
#
################################################################################

TITLE="USAGE BY USERS"
VERSION="v0.1 (2012-08-02)"
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
mode="cpu"
uidmin=500
verbose=0

NB_CPU=$(grep -c processor /proc/cpuinfo)
MAX_CPU=$((100*$NB_CPU))
MAX_MEM=100

################################################################################

# Print the revision number
print_revision() {
    echo "$PROGNAME - $VERSION"
}

# Print a short usage statement
print_usage() {
    echo "Usage:"
    echo "$PROGNAME [-v] -w <limit> -c <limit> [-m <cpu|mem|procs>] [-u <uid>]"
}

# Print detailed help information
print_help() {
    print_revision
    echo -e "$AUTHOR\n\nCheck CPU percent used by each users on local machine\n"
    print_usage

    /bin/cat <<__EOT

Options:
  -h    Print detailed help screen
  -V    Print version information
  -v    Enable verbose display (repeat to increase verbosity)
  -w PERCENT
        Warning exit status if more than PERCENT% of CPU is used by an user
  -c PERCENT
        Critical exit status if more than PERCENT% of CPU is used by an user
  -m cpu|mem|procs [default: cpu]
        Display CPU usage, memory usage or nb of processes per users
  -u UID [default: $uidmin]
        Exclude users which have a lower UID
__EOT
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
            warn_=$2
            shift
            ;;
        --critical|-c)
            crit_=$2
            shift
            ;;
        --mode|-m)
            mode=$2
            shift
            ;;
        --uidmin|-u)
            uidmin=$2
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

if [[ -z "$warn_" || -z "$crit_" ]]; then
    echo "$PROGNAME: WARNING and/or CRITICAL values must be defined"
    print_usage
    exit $STATE_UNKNOWN
fi

if [[ $(echo $warn_ | egrep "^[0-9]+$" -c) -ne 1 || $(echo $crit_ | egrep "^[0-9]+$" -c) -ne 1  ]]; then
    echo "$PROGNAME: WARNING and CRITICAL values must be integers"
    print_usage
    exit $STATE_UNKNOWN
fi

if [[ ! $warn_ -ge 0 || ! $crit_ -ge 0 ]]; then
    echo "$PROGNAME: WARNING and CRITICAL values must be integers"
    print_usage
    exit $STATE_UNKNOWN
fi

if [ $warn_ -gt $crit_ ]; then
    echo "$PROGNAME: Value of WARNING must be lower than CRITICAL"
    print_usage
    exit $STATE_UNKNOWN
fi

if [[ -z "$mode" || $(echo "$mode" | egrep "^(cpu|mem|procs)$" -c) = 0 ]]; then
    echo "$PROGNAME: Mode must be set to either cpu, mem or procs"
    print_usage
    exit $STATE_UNKNOWN
fi

################################################################################

warn=$warn_
crit=$crit_

if [[ "$mode" = "cpu" ]]; then
    sort_col=2
    # Change percent values according to actual nb of CPUs
    warn=$(echo "$warn_*$MAX_CPU/100" | bc)
    crit=$(echo "$crit_*$MAX_CPU/100" | bc)
elif [[ "$mode" = "mem" ]]; then
    sort_col=3
elif [[ "$mode" = "procs" ]]; then
    sort_col=4
fi

################################################################################

# Get ps output, aggregate by users, and sort them by CPU usage.
raw_output=$(ps -eo user,pcpu,pmem | tail -n +2 | \
    awk '{num[$1]++; cpu[$1] += $2; mem[$1] += $3}
        END {for (user in cpu)
            printf("%s %.2f %.2f %d\n", user, cpu[user], mem[user], num[user])
        }' | sort -rn -k${sort_col} | sed 's/ /:/g')

state_string="UNKNOWN"
nb=1
for line in $(echo $raw_output); do
    ps_user=$(echo $line | awk -F: '{print $1}')
    ps_cpu=$(echo $line | awk -F: '{print $2}')
    ps_mem=$(echo $line | awk -F: '{print $3}')
    ps_procs=$(echo $line | awk -F: '{print $4}')
    if [[ "$mode" = "cpu" ]]; then
        ps_value=$ps_cpu
        ps_unit="%"
        ps_min="0"
        ps_max="$MAX_CPU"
    elif [[ "$mode" = "mem" ]]; then
        ps_value=$ps_mem
        ps_unit="%"
        ps_min="0"
        ps_max="$MAX_MEM"
    elif [[ "$mode" = "procs" ]]; then
        ps_value=$ps_procs
        ps_unit=""
        ps_min=""
        ps_max=""
    fi
    # Work only with users above the given UID
    if [[ $(id -u $ps_user 2>/dev/null) -ge $uidmin ]]; then
        # Because results are already sorted by usage, the first row is the
        # higher value, so it's enought to use it to check the state.
        if [[ $nb -eq 1 ]]; then
            if [[ $(echo "$ps_value >= $crit" | bc) -eq 1 ]]; then
                state=$STATE_CRITICAL
                state_string="CRITICAL"
            elif [[ $(echo "$ps_value >= $warn" | bc) -eq 1 ]]; then
                state=$STATE_WARNING
                state_string="WARNING"
            else
                state=$STATE_OK
                state_string="OK"
            fi
        fi
        output="${output}$ps_user:$ps_value${ps_unit}; "
        perfdata="${perfdata} '$ps_user'=$ps_value${ps_unit};$warn;$crit;$ps_min;$ps_max"
        nb=$(($nb+1))
    fi
done

output=$(echo "$output" | sed 's/; $//')
perfdata=$(echo "$perfdata" | sed 's/ //')

# Display the text and perfdata result
echo -n "$(echo $mode | tr a-z A-Z) $TITLE $state_string"

if [[ $verbose -lt 1 ]]; then
    echo -n " - $(echo $output | awk '{print $1" "$2}')"
    if [[ $(echo $output | wc -w) -gt 2 ]]; then
        echo -n " (...)"
    fi
else
    echo -n " - $output"
fi
echo " | $perfdata"

if [[ $verbose -ge 2 ]]; then
    cat << EOT__
Debugging information:
  Nb of CPUs: $NB_CPU
  Warning threshold: $warn (user input: $warn_)
  Critical threshold: $crit (user input: $crit_)
  Mode: $mode
  Verbosity level: $verbose
  Raw ps output (after sorting):
$raw_output
EOT__
fi

# Exit with state value
exit $state

################################################################################
# Code from castorpilot:
ps -eo user,pcpu,pmem | tail -n +2 | awk '{num[$1]++; cpu[$1] += $2; mem[$1] += $3} END{printf("NPROC\tUSER\tCPU\tMEM\n"); for (user in cpu) printf("%d\t%s\t%.2f%\t%.2f%\n",num[user], user, cpu[user], mem[user]) }'
